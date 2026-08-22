#!/usr/bin/env python3
"""Build a leakage-resistant function-Jac evaluation suite.

The builder joins the composer master to the original MultiPL-T records,
clusters the *full source corpus* by normalized Python AST shape, selects one
strong idiomatic composer representative per cluster, and emits:

  public/dev.jsonl, public/test.jsonl
      Prompts and visible prefixes. Safe inputs for generation.

  private/dev.jsonl, private/test.jsonl
      Grader problems with hidden Jac tests and references. Do not train on or
      send these files to a generation model.

  denylist_ids.txt
      Every MultiPL-T source ID in a selected AST cluster, including IDs not yet
      present in composer. Training exports must reject all of these IDs.

  denylist_clusters.txt, clusters.jsonl, manifest.json, README.md
      Audit and reproducibility metadata.

Each selected source creates two tasks:
  - completion: continue a held-out Jac function from an early body prefix.
  - translation: translate the complete Python function to Jac.

The output directory must not already exist. This prevents accidental mutation
of a frozen split. Build to a new version directory when the policy changes.

Example:
  HF_HUB_OFFLINE=1 .venv/bin/python scripts/build_function_eval.py \
      --composer data/composer_dataset.jsonl \
      --out-dir evals/function/v1 \
      --dev-count 200 --test-count 500
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
import math
import os
import re
import shutil
import sys
import warnings
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"
CLUSTER_ALGORITHM = "python-ast-shape-v1"
DEFAULT_SEED = "jac-function-eval-v1"
# Only declarations prove paradigm escalation. Bare words such as `visit` or
# `report` can be ordinary function names and must not be mechanically penalized.
FORBIDDEN_OSP = ["node", "edge", "walker"]
REQUIRED_SYNTAX = ["no_python_syntax", "no_test_blocks"]
STYLE_DIAGNOSTICS = ["typed_def", "no_dynamic_types", "no_import_py"]
DEF_RE_TEMPLATE = r"\bdef(?::\w+)?\s+{name}\s*\("


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, ensure_ascii=False) + "\n")


def load_id_file(path: Path | None) -> set[int]:
    if path is None:
        return set()
    try:
        return {
            int(line.strip())
            for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        }
    except ValueError as exc:
        raise ValueError(f"{path} must contain one integer source ID per line") from exc


def load_composer_snapshot(path: Path) -> tuple[dict[int, dict[str, Any]], str]:
    """Read one immutable byte snapshot even if the live master later grows."""
    raw = path.read_bytes()
    rows: dict[int, dict[str, Any]] = {}
    for line_no, line in enumerate(raw.splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
            source_id = int(row["id"])
        except (json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
            raise ValueError(f"{path}:{line_no}: invalid composer row: {exc}") from exc
        if source_id in rows:
            raise ValueError(f"{path}:{line_no}: duplicate composer id {source_id}")
        if not isinstance(row.get("jac"), str) or not row["jac"].strip():
            raise ValueError(f"{path}:{line_no}: id {source_id} has no Jac source")
        rows[source_id] = row
    return rows, sha256_bytes(raw)


class _LocalCollector(ast.NodeVisitor):
    """Collect function-local names while leaving called globals meaningful."""

    def __init__(self) -> None:
        self.names: set[str] = set()

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        for arg in (
            *node.args.posonlyargs,
            *node.args.args,
            *node.args.kwonlyargs,
        ):
            self.names.add(arg.arg)
        if node.args.vararg:
            self.names.add(node.args.vararg.arg)
        if node.args.kwarg:
            self.names.add(node.args.kwarg.arg)
        for statement in node.body:
            self.visit(statement)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:
        self.visit_FunctionDef(node)  # type: ignore[arg-type]

    def visit_Name(self, node: ast.Name) -> None:
        if isinstance(node.ctx, (ast.Store, ast.Del)):
            self.names.add(node.id)

    def visit_Import(self, node: ast.Import) -> None:
        for alias in node.names:
            self.names.add(alias.asname or alias.name.split(".")[0])

    def visit_ImportFrom(self, node: ast.ImportFrom) -> None:
        for alias in node.names:
            self.names.add(alias.asname or alias.name)


class _ShapeCanonicalizer(ast.NodeTransformer):
    """Normalize names and literal values while preserving control/data shape."""

    def __init__(self, local_names: set[str]) -> None:
        self.local_names = local_names
        self.name_map: dict[str, str] = {}

    def canonical_name(self, name: str) -> str:
        if name not in self.name_map:
            self.name_map[name] = f"v{len(self.name_map)}"
        return self.name_map[name]

    @staticmethod
    def _without_docstring(body: list[ast.stmt]) -> list[ast.stmt]:
        if (
            body
            and isinstance(body[0], ast.Expr)
            and isinstance(body[0].value, ast.Constant)
            and isinstance(body[0].value.value, str)
        ):
            return body[1:]
        return body

    def visit_Module(self, node: ast.Module) -> ast.AST:
        node.body = self._without_docstring(node.body)
        return self.generic_visit(node)

    def visit_FunctionDef(self, node: ast.FunctionDef) -> ast.AST:
        node.name = "fn"
        node.decorator_list = []
        node.returns = None
        node.type_comment = None
        node.body = self._without_docstring(node.body)
        return self.generic_visit(node)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> ast.AST:
        node.name = "fn"
        node.decorator_list = []
        node.returns = None
        node.type_comment = None
        node.body = self._without_docstring(node.body)
        return self.generic_visit(node)

    def visit_arg(self, node: ast.arg) -> ast.AST:
        if node.arg in self.local_names:
            node.arg = self.canonical_name(node.arg)
        node.annotation = None
        node.type_comment = None
        return node

    def visit_Name(self, node: ast.Name) -> ast.AST:
        if node.id in self.local_names:
            node.id = self.canonical_name(node.id)
        return node

    def visit_Constant(self, node: ast.Constant) -> ast.AST:
        if node.value is None or isinstance(node.value, bool):
            return node
        node.value = f"<{type(node.value).__name__}>"
        node.kind = None
        return node


def ast_shape_fingerprint(source: str) -> str:
    """Return the stable full-corpus leakage-cluster fingerprint."""
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", SyntaxWarning)
        tree = ast.parse(source)
    collector = _LocalCollector()
    collector.visit(tree)
    tree = _ShapeCanonicalizer(collector.names).visit(tree)
    ast.fix_missing_locations(tree)
    canonical = ast.dump(tree, annotate_fields=True, include_attributes=False)
    return hashlib.sha256(canonical.encode()).hexdigest()


def selection_hash(seed: str, value: str) -> str:
    return hashlib.sha256(f"{seed}\0{value}".encode()).hexdigest()


def index_artifacts(root: Path, composer_ids: set[int]) -> tuple[dict[int, dict[str, Any]], set[int]]:
    """Find trusted floor functions/tests already produced by the pipeline."""
    best: dict[int, tuple[tuple[int, int], dict[str, Any]]] = {}
    test_hashes: dict[int, set[str]] = defaultdict(set)
    for path in root.glob("**/work/*.json"):
        try:
            row = json.loads(path.read_text(encoding="utf-8"))
            source_id = int(row.get("id"))
        except (OSError, json.JSONDecodeError, TypeError, ValueError):
            continue
        if source_id not in composer_ids:
            continue
        floor = row.get("floor_fn")
        tests = row.get("test_blocks")
        if not isinstance(floor, str) or not floor.strip():
            continue
        if not isinstance(tests, str) or not tests.strip():
            continue
        test_hashes[source_id].add(sha256_bytes(tests.strip().encode()))
        rank = (tests.count('test "'), len(tests))
        if source_id not in best or rank > best[source_id][0]:
            best[source_id] = (rank, {"floor_fn": floor.strip(), "test_blocks": tests.strip(), "path": str(path)})
    conflicts = {source_id for source_id, hashes in test_hashes.items() if len(hashes) > 1}
    return {source_id: value[1] for source_id, value in best.items()}, conflicts


def split_completion(reference: str, entrypoint: str, fraction: float = 0.30) -> tuple[str, str]:
    """Split full Jac into visible early prefix and hidden causal continuation."""
    match = re.search(
        DEF_RE_TEMPLATE.format(name=re.escape(entrypoint)), reference, re.MULTILINE
    )
    if not match:
        raise ValueError(f"cannot find Jac def for entrypoint {entrypoint!r}")
    opening = reference.find("{", match.end())
    closing = reference.rfind("}")
    if opening < 0 or closing <= opening:
        raise ValueError(f"cannot find function braces for {entrypoint!r}")

    body = reference[opening + 1 : closing]
    lines = body.splitlines(keepends=True)
    substantive = [index for index, line in enumerate(lines) if line.strip()]
    if len(substantive) <= 1:
        cut = 0
    else:
        visible_count = max(1, math.floor(len(substantive) * fraction))
        last_visible = substantive[min(visible_count - 1, len(substantive) - 2)]
        cut = sum(len(line) for line in lines[: last_visible + 1])

    prefix = reference[: opening + 1] + body[:cut]
    continuation = body[cut:] + reference[closing:]
    if not continuation.strip():
        raise ValueError(f"empty completion target for {entrypoint!r}")
    return prefix, continuation


def completion_prompt(prefix: str) -> str:
    return (
        "Continue the Jac source below. Preserve the existing signature and behavior. "
        "Return only the missing Jac continuation; do not repeat the visible prefix and "
        "do not add Markdown fences.\n\n"
        + prefix
    )


def translation_prompt(python_source: str, entrypoint: str) -> str:
    return (
        "Translate the Python function below into idiomatic, statically typed Jac. "
        f"Keep the entrypoint name `{entrypoint}` and preserve behavior exactly. "
        "Return only the complete Jac source. Do not add tests, OSP constructs, or "
        "Markdown prose.\n\n```python\n"
        + python_source.rstrip()
        + "\n```"
    )


def make_tasks(
    source_id: int,
    split: str,
    cluster_id: str,
    source: dict[str, Any],
    composer: dict[str, Any],
    artifact: dict[str, Any],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    entrypoint = str(source["entrypoint"])
    python_source = str(source["content"])
    reference = str(composer["jac"]).strip()
    prefix, reference_completion = split_completion(reference, entrypoint)
    common_public = {
        "source_id": source_id,
        "split": split,
        "track": "function",
        "entrypoint": entrypoint,
        "cluster_id": cluster_id,
    }
    common_private = {
        **common_public,
        "test_blocks": artifact["test_blocks"],
        "required_features": REQUIRED_SYNTAX,
        "forbidden_features": FORBIDDEN_OSP,
        "style_diagnostics": STYLE_DIAGNOSTICS,
        "floor_jac": artifact["floor_fn"],
        "idiomatic_jac": reference,
    }

    completion_id = f"fn-complete-{source_id}"
    translation_id = f"fn-translate-{source_id}"
    public = [
        {
            **common_public,
            "id": completion_id,
            "task": "completion",
            "prefix": prefix,
            "prompt": completion_prompt(prefix),
        },
        {
            **common_public,
            "id": translation_id,
            "task": "translation",
            "python": python_source,
            "prompt": translation_prompt(python_source, entrypoint),
        },
    ]
    private = [
        {
            **common_private,
            "id": completion_id,
            "task": "completion",
            "prefix": prefix,
            "reference_completion": reference_completion,
        },
        {
            **common_private,
            "id": translation_id,
            "task": "translation",
        },
    ]
    return public, private


def file_manifest(root: Path) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for path in sorted(root.rglob("*")):
        if path.is_file() and path.name != "manifest.json":
            result[str(path.relative_to(root))] = {
                "bytes": path.stat().st_size,
                "sha256": sha256_file(path),
            }
    return result


def build(args: argparse.Namespace) -> Path:
    if args.out_dir.exists():
        raise FileExistsError(
            f"refusing to modify existing eval directory: {args.out_dir}; use a new version"
        )
    if args.dev_count <= 0 or args.test_count <= 0:
        raise ValueError("dev-count and test-count must be positive")
    if not 0 < args.completion_fraction < 1:
        raise ValueError("completion-fraction must be between 0 and 1")

    composer, composer_hash = load_composer_snapshot(args.composer)
    excluded_source_ids = load_id_file(args.exclude_ids)
    artifacts, artifact_conflicts = index_artifacts(args.artifact_root, set(composer))

    os.environ.setdefault("HF_HUB_OFFLINE", "1")
    try:
        from datasets import load_dataset
    except ImportError as exc:
        raise RuntimeError(
            "the `datasets` package is required; run this with `.venv/bin/python`"
        ) from exc

    dataset = load_dataset(args.dataset, split="train")
    source_by_id: dict[int, dict[str, Any]] = {}
    cluster_members: dict[str, list[int]] = defaultdict(list)
    parse_failures: list[int] = []
    duplicate_source_rows = 0
    ambiguous_source_ids: set[int] = set()
    for raw in dataset:
        row = dict(raw)
        source_id = int(row["id"])
        if source_id in source_by_id:
            duplicate_source_rows += 1
            prior = source_by_id[source_id]
            identity_fields = ("sha1", "content", "entrypoint")
            if any(prior.get(key) != row.get(key) for key in identity_fields):
                raise ValueError(f"source dataset has conflicting source code for id {source_id}")
            if prior.get("tests") != row.get("tests") or prior.get("coverage") != row.get("coverage"):
                ambiguous_source_ids.add(source_id)
            if len(row.get("tests") or []) > len(prior.get("tests") or []):
                row["cluster_id"] = prior["cluster_id"]
                source_by_id[source_id] = row
            continue
        try:
            fingerprint = ast_shape_fingerprint(str(row["content"]))
        except (SyntaxError, ValueError):
            parse_failures.append(source_id)
            fingerprint = "parse-" + hashlib.sha256(str(row["content"]).encode()).hexdigest()
        row["cluster_id"] = fingerprint
        source_by_id[source_id] = row
        cluster_members[fingerprint].append(source_id)

    missing_source = sorted(set(composer) - set(source_by_id))
    if missing_source:
        raise ValueError(f"{len(missing_source)} composer IDs are absent from source dataset")

    eligible_by_cluster: dict[str, list[int]] = defaultdict(list)
    exclusion_counts: dict[str, int] = defaultdict(int)
    for source_id, composer_row in composer.items():
        source = source_by_id[source_id]
        cluster_id = str(source["cluster_id"])
        if source_id in excluded_source_ids:
            exclusion_counts["prior_reference_failure"] += 1
            continue
        if source_id in ambiguous_source_ids:
            exclusion_counts["ambiguous_source_id"] += 1
            continue
        if composer_row.get("source") != "idiomatic":
            exclusion_counts["not_idiomatic"] += 1
            continue
        if int(source.get("coverage") or 0) < args.min_coverage:
            exclusion_counts["low_coverage"] += 1
            continue
        if len(source.get("tests") or []) < args.min_tests:
            exclusion_counts["too_few_tests"] += 1
            continue
        if source_id in artifact_conflicts:
            exclusion_counts["conflicting_test_artifacts"] += 1
            continue
        if source_id not in artifacts:
            exclusion_counts["missing_test_artifact"] += 1
            continue
        if len(cluster_members[cluster_id]) > args.max_cluster_size:
            exclusion_counts["cluster_too_large"] += 1
            continue
        try:
            split_completion(str(composer_row["jac"]), str(source["entrypoint"]), args.completion_fraction)
        except ValueError:
            exclusion_counts["unsplittable_jac"] += 1
            continue
        eligible_by_cluster[cluster_id].append(source_id)

    representatives: list[tuple[str, int]] = []
    for cluster_id, source_ids in eligible_by_cluster.items():
        source_id = min(
            source_ids,
            key=lambda item: (
                -len(source_by_id[item].get("tests") or []),
                selection_hash(args.seed, str(item)),
            ),
        )
        representatives.append((cluster_id, source_id))
    representatives.sort(key=lambda item: selection_hash(args.seed, item[0]))

    required = args.dev_count + args.test_count
    if len(representatives) < required:
        raise ValueError(
            f"only {len(representatives)} eligible clusters for {required} requested records"
        )
    selected = representatives[:required]
    assignments = {
        cluster_id: ("dev" if index < args.dev_count else "test", source_id)
        for index, (cluster_id, source_id) in enumerate(selected)
    }

    stage = args.out_dir.parent / f".{args.out_dir.name}.building-{os.getpid()}"
    if stage.exists():
        shutil.rmtree(stage)
    (stage / "public").mkdir(parents=True)
    (stage / "private").mkdir(parents=True)
    try:
        public_rows: dict[str, list[dict[str, Any]]] = {"dev": [], "test": []}
        private_rows: dict[str, list[dict[str, Any]]] = {"dev": [], "test": []}
        cluster_rows: list[dict[str, Any]] = []
        deny_ids: set[int] = set()

        for cluster_id, (split, source_id) in assignments.items():
            members = sorted(cluster_members[cluster_id])
            deny_ids.update(members)
            public, private = make_tasks(
                source_id,
                split,
                cluster_id,
                source_by_id[source_id],
                composer[source_id],
                artifacts[source_id],
            )
            # Recompute split with the configured fraction when it differs from default.
            if args.completion_fraction != 0.30:
                prefix, continuation = split_completion(
                    str(composer[source_id]["jac"]),
                    str(source_by_id[source_id]["entrypoint"]),
                    args.completion_fraction,
                )
                public[0]["prefix"] = prefix
                public[0]["prompt"] = completion_prompt(prefix)
                private[0]["prefix"] = prefix
                private[0]["reference_completion"] = continuation
            public_rows[split].extend(public)
            private_rows[split].extend(private)
            cluster_rows.append(
                {
                    "cluster_id": cluster_id,
                    "split": split,
                    "representative_id": source_id,
                    "member_count": len(members),
                    "member_ids": members,
                    "current_composer_member_ids": sorted(set(members) & set(composer)),
                    "tests": len(source_by_id[source_id].get("tests") or []),
                    "coverage": source_by_id[source_id].get("coverage"),
                }
            )

        for split in ("dev", "test"):
            write_jsonl(stage / "public" / f"{split}.jsonl", public_rows[split])
            write_jsonl(stage / "private" / f"{split}.jsonl", private_rows[split])
        write_jsonl(stage / "clusters.jsonl", sorted(cluster_rows, key=lambda row: (row["split"], row["cluster_id"])))
        (stage / "denylist_ids.txt").write_text(
            "".join(f"{source_id}\n" for source_id in sorted(deny_ids)), encoding="utf-8"
        )
        (stage / "denylist_clusters.txt").write_text(
            "".join(f"{cluster_id}\n" for cluster_id in sorted(assignments)), encoding="utf-8"
        )
        (stage / "README.md").write_text(
            "# Function Jac evaluation v1\n\n"
            "This directory is generated by `scripts/build_function_eval.py`.\n\n"
            "- `public/`: prompts and visible prefixes for model generation.\n"
            "- `private/`: hidden tests and references for `scripts/eval_jac.py`. Never train on these files.\n"
            "- `denylist_ids.txt`: reject these source IDs from every training export.\n"
            "- `denylist_clusters.txt`: normalized Python AST clusters reserved by this eval.\n"
            "- `clusters.jsonl`: representative and complete source-cluster membership.\n\n"
            "The manifest status is `candidate_unvalidated` until all reference solutions pass the private tests under the pinned Jac toolchain.\n",
            encoding="utf-8",
        )

        current_denied = set(composer) & deny_ids
        cluster_sizes = [len(cluster_members[cluster_id]) for cluster_id in assignments]
        manifest = {
            "schema_version": 1,
            "status": "candidate_unvalidated",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "dataset": {
                "name": args.dataset,
                "split": "train",
                "rows": len(dataset),
                "unique_ids": len(source_by_id),
                "duplicate_source_rows": duplicate_source_rows,
                "ambiguous_source_ids": sorted(ambiguous_source_ids),
                "fingerprint": getattr(dataset, "_fingerprint", None),
            },
            "composer_snapshot": {
                "path": str(args.composer),
                "rows": len(composer),
                "sha256": composer_hash,
            },
            "selection": {
                "seed": args.seed,
                "cluster_algorithm": CLUSTER_ALGORITHM,
                "dev_sources": args.dev_count,
                "test_sources": args.test_count,
                "task_variants_per_source": 2,
                "min_coverage": args.min_coverage,
                "min_tests": args.min_tests,
                "max_cluster_size": args.max_cluster_size,
                "completion_fraction": args.completion_fraction,
                "excluded_source_ids": sorted(excluded_source_ids),
                "exclude_ids_path": str(args.exclude_ids) if args.exclude_ids else None,
                "exclude_ids_sha256": sha256_file(args.exclude_ids) if args.exclude_ids else None,
                "eligible_clusters": len(representatives),
                "exclusion_counts": dict(sorted(exclusion_counts.items())),
            },
            "counts": {
                "public_dev_tasks": len(public_rows["dev"]),
                "public_test_tasks": len(public_rows["test"]),
                "private_dev_tasks": len(private_rows["dev"]),
                "private_test_tasks": len(private_rows["test"]),
                "reserved_clusters": len(assignments),
                "denied_full_source_ids": len(deny_ids),
                "denied_current_composer_ids": len(current_denied),
                "cluster_size_min": min(cluster_sizes),
                "cluster_size_max": max(cluster_sizes),
                "cluster_size_mean": round(sum(cluster_sizes) / len(cluster_sizes), 3),
                "source_parse_fallbacks": len(parse_failures),
                "duplicate_source_rows": duplicate_source_rows,
                "ambiguous_source_ids": len(ambiguous_source_ids),
                "artifact_conflicts": len(artifact_conflicts),
            },
            "files": file_manifest(stage),
        }
        (stage / "manifest.json").write_text(
            json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        stage.rename(args.out_dir)
    except BaseException:
        shutil.rmtree(stage, ignore_errors=True)
        raise
    return args.out_dir


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--composer", type=Path, default=Path("data/composer_dataset.jsonl"))
    parser.add_argument("--artifact-root", type=Path, default=Path("data"))
    parser.add_argument("--out-dir", type=Path, default=Path("evals/function/v1"))
    parser.add_argument("--dataset", default=DATASET)
    parser.add_argument("--seed", default=DEFAULT_SEED)
    parser.add_argument("--dev-count", type=int, default=200)
    parser.add_argument("--test-count", type=int, default=500)
    parser.add_argument("--min-coverage", type=int, default=100)
    parser.add_argument("--min-tests", type=int, default=5)
    parser.add_argument("--max-cluster-size", type=int, default=50)
    parser.add_argument("--completion-fraction", type=float, default=0.30)
    parser.add_argument(
        "--exclude-ids",
        type=Path,
        help="one failed reference source ID per line; deterministic replacement uses reserves",
    )
    args = parser.parse_args()

    try:
        output = build(args)
    except (FileExistsError, RuntimeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    manifest = json.loads((output / "manifest.json").read_text())
    print(json.dumps(manifest["counts"], indent=2, sort_keys=True))
    print(f"wrote candidate eval suite to {output}")
    print("status: candidate_unvalidated (run reference validation before sealing)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
