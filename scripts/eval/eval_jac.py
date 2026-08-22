#!/usr/bin/env python3
"""Grade generated Jac for function and OSP evaluation suites.

This script is deliberately model-provider neutral. A generation runner writes
samples to JSONL; this grader checks and tests them under an isolated temporary
directory, then emits per-sample results and aggregate pass@k metrics.

Problem JSONL schema
--------------------
Required:
  {"id": "problem-id", "track": "function" | "osp"}

Optional:
  "prompt": str                 Stored for generation; ignored by the grader.
  "prefix": str                 Prepended to a sample's `completion` field.
  "suffix": str                 Appended to a sample's `completion` field.
  "test_blocks": str | [str]    Hidden Jac `test` blocks.
  "required_features": [str]    Objective, task-specific structural contract.
  "forbidden_features": [str]   Objective, task-specific structural contract.
  "floor_jac": str              Optional reference-similarity diagnostic.
  "idiomatic_jac": str          Optional reference-similarity diagnostic.

Sample JSONL schema
-------------------
Required:
  {"problem_id": "problem-id", "sample_id": 0, ...}

Provide one of:
  "jac": str                    Complete Jac source.
  "candidate": str              Complete Jac source (pipeline compatibility).
  "output": str                 Complete raw model output.
  "completion": str             Body/text assembled as prefix+completion+suffix.

A complete source may be raw Jac or one fenced ```jac block. Hidden tests never
appear in the generated-source artifact or output results.

Supported feature contract names
--------------------------------
  node, edge, walker, ability_entry, spawn, visit, report, disengage,
  graph_connect, graph_reference, obj, typed_def, typed_has, no_dynamic_types,
  no_python_syntax, no_import_py, no_test_blocks

Examples
--------
  python scripts/eval_jac.py \
      --problems evals/py2jac/v1/problems.jsonl \
      --samples runs/model-a/samples.jsonl \
      --out-dir runs/model-a/graded \
      --k 1,5,10 --workers 2

Outputs:
  results.jsonl  One row per sample.
  summary.json   Overall and per-track rates, pass@k, status counts, metadata.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import signal
import subprocess
import tempfile
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime, timezone
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any, Iterable


FENCED_JAC_RE = re.compile(r"```jac\s*\n?(.*?)```", re.IGNORECASE | re.DOTALL)
ANY_FENCE_RE = re.compile(r"```")
TOKEN_RE = re.compile(r"\w+|[^\w\s]", re.UNICODE)

FEATURE_PATTERNS: dict[str, re.Pattern[str]] = {
    "node": re.compile(r"(?m)^\s*node(?::\w+)?\s+\w+\s*\{"),
    "edge": re.compile(r"(?m)^\s*edge(?::\w+)?\s+\w+\s*\{"),
    "walker": re.compile(r"(?m)^\s*walker(?::\w+)?\s+\w+\s*\{"),
    "ability_entry": re.compile(r"\bcan\b[^\n{]*\bwith\b[^\n{]*\bentry\b"),
    "spawn": re.compile(r"\bspawn\b"),
    "visit": re.compile(r"\bvisit\b"),
    "report": re.compile(r"\breport\b"),
    "disengage": re.compile(r"\bdisengage\b"),
    "graph_connect": re.compile(r"(?:\+\+>|<\+\+|\+>[^\n]*:\+>)"),
    "graph_reference": re.compile(r"\[(?:<--|-->|<-->|\?-->|<--\?)"),
    "obj": re.compile(r"(?m)^\s*obj(?::\w+)?\s+\w+\s*\{"),
    "typed_def": re.compile(
        r"\bdef(?::\w+)?\s+\w+\s*\([^)]*:\s*[^,)]+(?:,[^)]*)?\)\s*->\s*[^\s{]+"
    ),
    "typed_has": re.compile(r"\bhas\s+\w+\s*:\s*[^;=,]+"),
    "no_dynamic_types": re.compile(r"$^"),  # computed, not directly matched
    "no_python_syntax": re.compile(r"$^"),
    "no_import_py": re.compile(r"$^"),
    "no_test_blocks": re.compile(r"$^"),
}

DYNAMIC_TYPE_RE = re.compile(
    r"(?::\s*|->\s*|\[\s*|\|\s*|,\s*)(?:Any|any|object)\b"
)
PYTHON_BLOCK_RE = re.compile(
    r"(?m)^\s*(?:def|class|if|elif|else|for|while|try|except|with)\b[^\n{]*:\s*(?:#.*)?$"
)
IMPORT_PY_RE = re.compile(
    r"\bimport:py\b|^\s*from\s+\S+\s+import\s+", re.MULTILINE
)
TEST_BLOCK_RE = re.compile(r'(?m)^\s*test\s+["\']')
RANGE_LEN_RE = re.compile(r"\brange\s*\(\s*len\s*\(")
INFRA_ERROR_RE = re.compile(
    r"embedded postgres|postgres not ready|could not connect to (?:the )?database|"
    r"connection to server.*failed|initdb|database system is starting up|"
    r"No space left on device",
    re.IGNORECASE | re.DOTALL,
)


@dataclass(frozen=True)
class ProcessResult:
    returncode: int | None
    stdout: str
    stderr: str
    elapsed_ms: float
    timed_out: bool = False
    launch_error: str | None = None


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open(encoding="utf-8") as handle:
        for line_no, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_no}: invalid JSON: {exc}") from exc
            if not isinstance(row, dict):
                raise ValueError(f"{path}:{line_no}: expected a JSON object")
            rows.append(row)
    return rows


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def extract_jac(text: str) -> tuple[str | None, str | None]:
    """Return (Jac source, extraction error)."""
    if not isinstance(text, str) or not text.strip():
        return None, "empty model output"
    matches = FENCED_JAC_RE.findall(text)
    if matches:
        if len(matches) != 1:
            return None, f"expected one fenced Jac block, found {len(matches)}"
        source = matches[0].strip()
        return (source, None) if source else (None, "empty fenced Jac block")
    if ANY_FENCE_RE.search(text):
        return None, "model output contains a fence but no complete ```jac block"
    return text.strip(), None


def assemble_source(problem: dict[str, Any], sample: dict[str, Any]) -> tuple[str | None, str | None]:
    if "completion" in sample:
        completion, error = extract_jac(str(sample.get("completion", "")))
        if error:
            return None, error
        return (
            str(problem.get("prefix", ""))
            + (completion or "")
            + str(problem.get("suffix", "")),
            None,
        )

    for key in ("jac", "candidate", "output"):
        if key in sample:
            return extract_jac(str(sample.get(key, "")))
    return None, "sample must contain jac, candidate, output, or completion"


def test_blocks(problem: dict[str, Any]) -> str:
    value = problem.get("test_blocks", "")
    if isinstance(value, list):
        return "\n\n".join(str(item).strip() for item in value if str(item).strip())
    return str(value).strip()


def feature_flags(source: str) -> dict[str, bool]:
    flags = {name: bool(pattern.search(source)) for name, pattern in FEATURE_PATTERNS.items()}
    flags["no_dynamic_types"] = not bool(DYNAMIC_TYPE_RE.search(source))
    flags["no_python_syntax"] = not bool(PYTHON_BLOCK_RE.search(source))
    flags["no_import_py"] = not bool(IMPORT_PY_RE.search(source))
    flags["no_test_blocks"] = not bool(TEST_BLOCK_RE.search(source))
    return flags


def static_diagnostics(source: str) -> dict[str, Any]:
    """Neutral static diagnostics; these are not combined into a style score."""
    flags = feature_flags(source)
    lines = source.splitlines()
    nonempty = [line for line in lines if line.strip()]
    lengths = [len(line) for line in nonempty]
    depth = 0
    max_depth = 0
    for character in source:
        if character == "{":
            depth += 1
            max_depth = max(max_depth, depth)
        elif character == "}":
            depth = max(0, depth - 1)
    return {
        "features": flags,
        "dynamic_type_mentions": len(DYNAMIC_TYPE_RE.findall(source)),
        "range_len_loops": len(RANGE_LEN_RE.findall(source)),
        "python_syntax_smell": not flags["no_python_syntax"],
        "import_py_smell": not flags["no_import_py"],
        "included_test_blocks": not flags["no_test_blocks"],
        "source_lines": len(lines),
        "nonempty_lines": len(nonempty),
        "max_line_length": max(lengths, default=0),
        "mean_line_length": round(sum(lengths) / len(lengths), 3) if lengths else 0.0,
        "long_lines_over_100": sum(length > 100 for length in lengths),
        "max_brace_depth": max_depth,
    }


def validate_contract(
    problem: dict[str, Any], flags: dict[str, bool]
) -> tuple[bool, list[str], list[str]]:
    required = [str(item) for item in problem.get("required_features", [])]
    forbidden = [str(item) for item in problem.get("forbidden_features", [])]
    unknown = sorted((set(required) | set(forbidden)) - set(FEATURE_PATTERNS))
    if unknown:
        raise ValueError(f"problem {problem['id']!r} has unknown feature names: {unknown}")
    missing = [name for name in required if not flags[name]]
    present_forbidden = [name for name in forbidden if flags[name]]
    return not missing and not present_forbidden, missing, present_forbidden


def normalized_similarity(source: str, reference: str) -> float:
    """Token similarity diagnostic; never treated as an idiomaticity score."""
    left = " ".join(TOKEN_RE.findall(source))
    right = " ".join(TOKEN_RE.findall(reference))
    if not left or not right:
        return 0.0
    return round(SequenceMatcher(None, left, right, autojunk=False).ratio(), 4)


def reference_diagnostics(problem: dict[str, Any], source: str) -> dict[str, Any] | None:
    floor = problem.get("floor_jac")
    idiomatic = problem.get("idiomatic_jac")
    if not isinstance(floor, str) and not isinstance(idiomatic, str):
        return None
    result: dict[str, Any] = {}
    if isinstance(floor, str):
        result["floor_similarity"] = normalized_similarity(source, floor)
    if isinstance(idiomatic, str):
        result["idiomatic_similarity"] = normalized_similarity(source, idiomatic)
    if "floor_similarity" in result and "idiomatic_similarity" in result:
        floor_score = result["floor_similarity"]
        idiom_score = result["idiomatic_similarity"]
        result["closer_reference"] = (
            "idiomatic" if idiom_score > floor_score
            else "floor" if floor_score > idiom_score
            else "tie"
        )
    result["note"] = "diagnostic token similarity; not an idiomaticity score"
    return result


def run_process(
    command: list[str], cwd: Path, timeout_s: float, env: dict[str, str]
) -> ProcessResult:
    start = time.perf_counter()
    try:
        process = subprocess.Popen(
            command,
            cwd=str(cwd),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
    except OSError as exc:
        return ProcessResult(
            None, "", "", (time.perf_counter() - start) * 1000, launch_error=str(exc)
        )

    try:
        stdout, stderr = process.communicate(timeout=timeout_s)
        return ProcessResult(
            process.returncode,
            stdout,
            stderr,
            (time.perf_counter() - start) * 1000,
        )
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
        return ProcessResult(
            process.returncode,
            stdout,
            stderr,
            (time.perf_counter() - start) * 1000,
            timed_out=True,
        )


def concise_output(result: ProcessResult, limit: int = 600) -> str:
    text = (result.stderr or result.stdout).strip()
    return text[-limit:]


def is_infra_failure(result: ProcessResult) -> bool:
    return bool(INFRA_ERROR_RE.search((result.stdout or "") + "\n" + (result.stderr or "")))


def infra_excerpt(result: ProcessResult, limit: int = 600) -> str:
    text = ((result.stdout or "") + "\n" + (result.stderr or "")).strip()
    match = INFRA_ERROR_RE.search(text)
    if not match:
        return text[-limit:]
    start = max(0, match.start() - limit // 4)
    return text[start : start + limit]


def set_infra_error(
    row: dict[str, Any], *, stage: str, error: str, returncode: int | None = None
) -> None:
    row.update(
        status="infra_error",
        stage=stage,
        error=error,
        returncode=returncode,
        test_pass=None,
        task_success=None,
    )


def grade_one(
    index: int,
    problem: dict[str, Any],
    sample: dict[str, Any],
    *,
    jac_bin: str,
    timeout_s: float,
    tmp_root: Path | None,
    jac_tmp: Path | None,
) -> tuple[int, dict[str, Any]]:
    problem_id = str(problem["id"])
    sample_id = sample.get("sample_id", index)
    hidden_tests = test_blocks(problem)
    has_behavior_tests = bool(hidden_tests)
    row: dict[str, Any] = {
        "problem_id": problem_id,
        "sample_id": sample_id,
        "track": problem.get("track", "function"),
        "status": None,
        "check_pass": False,
        "has_behavior_tests": has_behavior_tests,
        "test_executed": False,
        "test_pass": False if has_behavior_tests else None,
        "task_success": False if has_behavior_tests else None,
    }

    source, extraction_error = assemble_source(problem, sample)
    if extraction_error or source is None:
        row.update(status="extract_fail", error=extraction_error)
        return index, row

    row["source_sha256"] = hashlib.sha256(source.encode()).hexdigest()
    diagnostics = static_diagnostics(source)
    row["static"] = diagnostics
    contract_pass, missing, forbidden = validate_contract(problem, diagnostics["features"])
    row["contract_pass"] = contract_pass
    if missing:
        row["missing_features"] = missing
    if forbidden:
        row["forbidden_features_present"] = forbidden
    references = reference_diagnostics(problem, source)
    if references:
        row["reference"] = references

    tmp_parent = str(tmp_root) if tmp_root else None
    with tempfile.TemporaryDirectory(prefix=f"jac_eval_{problem_id}_", dir=tmp_parent) as tmp:
        cwd = Path(tmp)
        env = dict(os.environ)
        if jac_tmp is not None:
            env["TMPDIR"] = str(jac_tmp)
        candidate_file = cwd / "candidate.jac"
        candidate_file.write_text(source.rstrip() + "\n", encoding="utf-8")

        checked = run_process(
            [jac_bin, "check", str(candidate_file)], cwd, timeout_s, env
        )
        row["check_ms"] = round(checked.elapsed_ms, 1)
        if checked.launch_error:
            set_infra_error(row, stage="check", error=checked.launch_error)
            return index, row
        if checked.timed_out:
            row.update(status="timeout", stage="check", error=concise_output(checked))
            return index, row
        if checked.returncode is None or checked.returncode < 0:
            row.update(
                status="tool_crash",
                stage="check",
                returncode=checked.returncode,
                error=concise_output(checked),
            )
            return index, row
        if checked.returncode != 0:
            if is_infra_failure(checked):
                set_infra_error(
                    row,
                    stage="check",
                    error=infra_excerpt(checked),
                    returncode=checked.returncode,
                )
            else:
                row.update(
                    status="check_fail",
                    returncode=checked.returncode,
                    error=concise_output(checked),
                )
            return index, row

        row["check_pass"] = True
        if not hidden_tests:
            row["status"] = "check_pass"
            return index, row

        guard_file = cwd / "guard.jac"
        guard_file.write_text(
            source.rstrip() + "\n\n" + hidden_tests.rstrip() + "\n", encoding="utf-8"
        )
        tested = run_process([jac_bin, "test", str(guard_file)], cwd, timeout_s, env)
        row["test_executed"] = True
        row["test_ms"] = round(tested.elapsed_ms, 1)
        if tested.launch_error:
            set_infra_error(row, stage="test", error=tested.launch_error)
            return index, row
        if tested.timed_out:
            row.update(status="timeout", stage="test", test_pass=False, error=concise_output(tested))
            return index, row
        if tested.returncode is None or tested.returncode < 0:
            row.update(
                status="tool_crash",
                stage="test",
                test_pass=False,
                returncode=tested.returncode,
                error=concise_output(tested),
            )
            return index, row
        if tested.returncode != 0:
            if is_infra_failure(tested):
                set_infra_error(
                    row,
                    stage="test",
                    error=infra_excerpt(tested),
                    returncode=tested.returncode,
                )
            else:
                row.update(
                    status="test_fail",
                    test_pass=False,
                    returncode=tested.returncode,
                    error=concise_output(tested),
                )
            return index, row

        row.update(
            status="pass" if contract_pass else "contract_fail",
            test_pass=True,
            task_success=contract_pass,
        )
        return index, row


def pass_at_k(n: int, correct: int, k: int) -> float | None:
    if n < k or n <= 0:
        return None
    if correct <= 0:
        return 0.0
    if n - correct < k:
        return 1.0
    return 1.0 - math.comb(n - correct, k) / math.comb(n, k)


def mean(values: Iterable[float]) -> float | None:
    items = list(values)
    return round(sum(items) / len(items), 6) if items else None


def aggregate(rows: list[dict[str, Any]], ks: list[int]) -> dict[str, Any]:
    status_counts = Counter(str(row["status"]) for row in rows)
    tested = [
        row
        for row in rows
        if row.get("has_behavior_tests") and row.get("status") != "infra_error"
    ]
    scored = [row for row in rows if row.get("task_success") is not None]

    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in scored:
        grouped[str(row["problem_id"])].append(row)

    pass_k: dict[str, Any] = {}
    for k in ks:
        estimates: list[float] = []
        for samples in grouped.values():
            n = len(samples)
            correct = sum(bool(sample["task_success"]) for sample in samples)
            estimate = pass_at_k(n, correct, k)
            if estimate is not None:
                estimates.append(estimate)
        pass_k[str(k)] = {
            "value": mean(estimates),
            "eligible_problems": len(estimates),
        }

    static_rows = [row["static"] for row in rows if isinstance(row.get("static"), dict)]
    feature_counts: Counter[str] = Counter()
    feature_names: set[str] = set()
    for diagnostics in static_rows:
        flags = diagnostics.get("features", {})
        feature_names.update(flags)
        for name, present in flags.items():
            if present and not name.startswith("no_"):
                feature_counts[name] += 1

    def feature_rate(name: str) -> float | None:
        return mean(
            bool(diagnostics.get("features", {}).get(name))
            for diagnostics in static_rows
        )

    def diagnostic_mean(name: str) -> float | None:
        return mean(
            float(diagnostics.get(name, 0))
            for diagnostics in static_rows
        )

    static_summary = {
        "typing": {
            "typed_def_rate": feature_rate("typed_def"),
            "no_dynamic_types_rate": feature_rate("no_dynamic_types"),
            "mean_dynamic_type_mentions": diagnostic_mean("dynamic_type_mentions"),
        },
        "transpiler_residue": {
            "no_python_syntax_rate": feature_rate("no_python_syntax"),
            "no_import_py_rate": feature_rate("no_import_py"),
            "no_embedded_test_blocks_rate": feature_rate("no_test_blocks"),
            "mean_range_len_loops": diagnostic_mean("range_len_loops"),
        },
        "readability_diagnostics": {
            "mean_source_lines": diagnostic_mean("source_lines"),
            "mean_line_length": diagnostic_mean("mean_line_length"),
            "mean_long_lines_over_100": diagnostic_mean("long_lines_over_100"),
            "mean_max_brace_depth": diagnostic_mean("max_brace_depth"),
        },
        "feature_rates": {
            name: feature_rate(name) for name in sorted(feature_names)
        },
        "note": "reported independently; no aggregate idiomaticity score",
    }

    problem_ids = {str(row["problem_id"]) for row in rows}
    return {
        "problems": len(problem_ids),
        "samples": len(rows),
        "complete": status_counts.get("infra_error", 0) == 0,
        "infra_errors": status_counts.get("infra_error", 0),
        "status_counts": dict(sorted(status_counts.items())),
        "check_rate": mean(bool(row.get("check_pass")) for row in rows),
        "behavior_test_rate": mean(bool(row.get("test_pass")) for row in tested),
        "task_success_rate": mean(bool(row.get("task_success")) for row in scored),
        "contract_rate": mean(bool(row.get("contract_pass")) for row in rows),
        "pass_at_k": pass_k,
        "feature_presence_samples": dict(sorted(feature_counts.items())),
        "static_diagnostics": static_summary,
        "compile_only_samples": sum(
            not row.get("has_behavior_tests") for row in rows
        ),
    }


def validate_inputs(
    problems: list[dict[str, Any]], samples: list[dict[str, Any]]
) -> dict[str, dict[str, Any]]:
    by_id: dict[str, dict[str, Any]] = {}
    for problem in problems:
        if "id" not in problem:
            raise ValueError("every problem requires an id")
        problem_id = str(problem["id"])
        if problem_id in by_id:
            raise ValueError(f"duplicate problem id: {problem_id}")
        track = str(problem.get("track", "function"))
        if track not in {"function", "osp"}:
            raise ValueError(f"problem {problem_id!r}: track must be function or osp")
        problem["track"] = track
        # Validate contract names before spending time on Jac subprocesses.
        validate_contract(problem, {name: False for name in FEATURE_PATTERNS})
        by_id[problem_id] = problem

    for index, sample in enumerate(samples):
        if "problem_id" not in sample:
            raise ValueError(f"sample {index} requires problem_id")
        problem_id = str(sample["problem_id"])
        if problem_id not in by_id:
            raise ValueError(f"sample {index} refers to unknown problem {problem_id!r}")
    return by_id


def jac_version(jac_bin: str) -> str | None:
    try:
        result = subprocess.run(
            [jac_bin, "--version"], capture_output=True, text=True, timeout=15
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    text = (result.stdout or result.stderr).strip()
    return text or None


def parse_ks(value: str) -> list[int]:
    try:
        ks = sorted({int(item) for item in value.split(",") if item.strip()})
    except ValueError as exc:
        raise argparse.ArgumentTypeError("--k must be comma-separated integers") from exc
    if not ks or any(k <= 0 for k in ks):
        raise argparse.ArgumentTypeError("--k values must be positive")
    return ks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--problems", type=Path, required=True)
    parser.add_argument("--samples", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--jac-bin", default="jac")
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--k", type=parse_ks, default=parse_ks("1,5,10"))
    parser.add_argument(
        "--tmp-root", type=Path, help="parent for isolated per-sample working directories"
    )
    parser.add_argument(
        "--jac-tmp",
        type=Path,
        help="optional shared Jac runtime TMPDIR; default inherits the environment",
    )
    args = parser.parse_args()

    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if args.workers <= 0:
        parser.error("--workers must be positive")
    if args.tmp_root:
        args.tmp_root.mkdir(parents=True, exist_ok=True)
    jac_tmp = args.jac_tmp
    if jac_tmp is not None:
        jac_tmp.mkdir(parents=True, exist_ok=True)

    problems = read_jsonl(args.problems)
    samples = read_jsonl(args.samples)
    by_id = validate_inputs(problems, samples)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    started = time.perf_counter()
    ordered: list[dict[str, Any] | None] = [None] * len(samples)
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(
                grade_one,
                index,
                by_id[str(sample["problem_id"])],
                sample,
                jac_bin=args.jac_bin,
                timeout_s=args.timeout,
                tmp_root=args.tmp_root,
                jac_tmp=jac_tmp,
            ): index
            for index, sample in enumerate(samples)
        }
        for future in as_completed(futures):
            index, row = future.result()
            ordered[index] = row

    results = [row for row in ordered if row is not None]
    results_path = args.out_dir / "results.jsonl"
    results_path.write_text(
        "".join(json.dumps(row, sort_keys=True) + "\n" for row in results),
        encoding="utf-8",
    )

    overall = aggregate(results, args.k)
    tracks = {
        track: aggregate([row for row in results if row["track"] == track], args.k)
        for track in ("function", "osp")
        if any(row["track"] == track for row in results)
    }
    summary = {
        "schema_version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "elapsed_s": round(time.perf_counter() - started, 3),
        "jac_version": jac_version(args.jac_bin),
        "configuration": {
            "timeout_s": args.timeout,
            "workers": args.workers,
            "k": args.k,
            "jac_tmp": str(jac_tmp.resolve()) if jac_tmp else None,
            "problems_sha256": sha256_file(args.problems),
            "samples_sha256": sha256_file(args.samples),
        },
        "overall": overall,
        "tracks": tracks,
        "notes": [
            "task_success requires hidden tests and any declared feature contract",
            "compile-only samples do not contribute to task_success or pass@k",
            "feature presence and reference similarity are diagnostics, not idiomaticity scores",
        ],
    }
    summary_path = args.out_dir / "summary.json"
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")

    print(json.dumps(overall, indent=2, sort_keys=True))
    print(f"wrote {results_path}")
    print(f"wrote {summary_path}")
    if not overall["complete"]:
        print("evaluation incomplete: resolve and rerun infrastructure errors")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
