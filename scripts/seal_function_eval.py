#!/usr/bin/env python3
"""Validate reference solutions and seal a function-Jac eval suite.

Sealing is intentionally strict:
  1. Verify every pre-validation file against manifest SHA-256 hashes.
  2. Verify public/private task IDs and completion reconstruction.
  3. Run each unique source reference through `jac check` and hidden `jac test`.
  4. Seal only if every reference passes and no infrastructure error occurs.

A full successful run writes `validation/`, creates `SEALED`, updates all file
hashes in `manifest.json`, and changes status to `sealed`. A failed run leaves
the candidate untouched and writes its report beside the eval directory.

Use `--limit` for a non-mutating smoke run. Limited or split-only runs never
seal the suite.

Examples:
  python scripts/seal_function_eval.py --eval-dir evals/function/v1 --limit 10
  python scripts/seal_function_eval.py --eval-dir evals/function/v1 --workers 6
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
import tempfile
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
if str(REPO) not in sys.path:
    sys.path.insert(0, str(REPO))

from scripts import build_function_eval as builder  # noqa: E402
from scripts import eval_jac  # noqa: E402


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
                raise ValueError(f"{path}:{line_no}: expected object")
            rows.append(row)
    return rows


def verify_manifest_files(eval_dir: Path, manifest: dict[str, Any]) -> None:
    expected = manifest.get("files")
    if not isinstance(expected, dict):
        raise ValueError("manifest has no file hash table")
    actual_paths = {
        str(path.relative_to(eval_dir))
        for path in eval_dir.rglob("*")
        if path.is_file() and path.name != "manifest.json"
    }
    expected_paths = set(expected)
    if actual_paths != expected_paths:
        missing = sorted(expected_paths - actual_paths)
        extra = sorted(actual_paths - expected_paths)
        raise ValueError(f"eval file set changed; missing={missing}, extra={extra}")
    for relative, metadata in expected.items():
        path = eval_dir / relative
        actual_hash = builder.sha256_file(path)
        if actual_hash != metadata.get("sha256"):
            raise ValueError(f"hash mismatch: {relative}")
        if path.stat().st_size != metadata.get("bytes"):
            raise ValueError(f"size mismatch: {relative}")


def load_and_verify_tasks(
    eval_dir: Path, splits: list[str]
) -> tuple[list[dict[str, Any]], dict[int, dict[str, Any]]]:
    private_rows: list[dict[str, Any]] = []
    public_ids: set[str] = set()
    for split in splits:
        public = read_jsonl(eval_dir / "public" / f"{split}.jsonl")
        private = read_jsonl(eval_dir / "private" / f"{split}.jsonl")
        public_ids.update(str(row["id"]) for row in public)
        private_rows.extend(private)
        for row in public:
            forbidden_public = {"test_blocks", "floor_jac", "idiomatic_jac", "reference_completion"}
            leaked = forbidden_public & set(row)
            if leaked:
                raise ValueError(f"public task {row.get('id')} contains private fields: {sorted(leaked)}")

    private_ids = {str(row["id"]) for row in private_rows}
    if len(private_ids) != len(private_rows):
        raise ValueError("duplicate private task IDs")
    if public_ids != private_ids:
        raise ValueError(
            f"public/private task ID mismatch: public-only={len(public_ids-private_ids)}, "
            f"private-only={len(private_ids-public_ids)}"
        )

    grouped: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for row in private_rows:
        grouped[int(row["source_id"])].append(row)

    references: dict[int, dict[str, Any]] = {}
    for source_id, rows in grouped.items():
        if len(rows) != 2 or {str(row.get("task")) for row in rows} != {"completion", "translation"}:
            raise ValueError(f"source {source_id} does not have one completion and one translation task")
        completion = next(row for row in rows if row["task"] == "completion")
        translation = next(row for row in rows if row["task"] == "translation")
        shared_fields = (
            "cluster_id",
            "entrypoint",
            "test_blocks",
            "floor_jac",
            "idiomatic_jac",
            "required_features",
            "forbidden_features",
        )
        for field in shared_fields:
            if completion.get(field) != translation.get(field):
                raise ValueError(f"source {source_id}: task variants disagree on {field}")
        reconstructed = str(completion.get("prefix", "")) + str(
            completion.get("reference_completion", "")
        )
        if reconstructed != str(completion["idiomatic_jac"]):
            raise ValueError(f"source {source_id}: completion target does not reconstruct reference")
        references[source_id] = translation
    return private_rows, references


def validate_references(
    references: list[tuple[int, dict[str, Any]]],
    *,
    jac_bin: str,
    workers: int,
    timeout_s: float,
    tmp_root: Path | None,
    jac_tmp: Path | None,
) -> list[dict[str, Any]]:
    ordered: list[dict[str, Any] | None] = [None] * len(references)
    started = time.perf_counter()
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {}
        for index, (source_id, problem) in enumerate(references):
            sample = {
                "problem_id": problem["id"],
                "sample_id": "reference",
                "jac": problem["idiomatic_jac"],
            }
            future = executor.submit(
                eval_jac.grade_one,
                index,
                problem,
                sample,
                jac_bin=jac_bin,
                timeout_s=timeout_s,
                tmp_root=tmp_root,
                jac_tmp=jac_tmp,
            )
            futures[future] = (index, source_id)

        completed = 0
        for future in as_completed(futures):
            index, source_id = futures[future]
            _, row = future.result()
            row["source_id"] = source_id
            ordered[index] = row
            completed += 1
            if completed % 25 == 0 or completed == len(references):
                elapsed = max(time.perf_counter() - started, 0.001)
                statuses = Counter(
                    str(item["status"]) for item in ordered if item is not None
                )
                print(
                    f"validated {completed}/{len(references)} "
                    f"({completed/elapsed:.2f}/s) statuses={dict(statuses)}",
                    flush=True,
                )
    return [row for row in ordered if row is not None]


def validate_reference_batches(
    references: list[tuple[int, dict[str, Any]]],
    *,
    jac_bin: str,
    batch_size: int,
    batch_timeout_s: float,
    fallback_timeout_s: float,
    tmp_root: Path | None,
    jac_tmp: Path | None,
) -> list[dict[str, Any]]:
    """Validate sequential multi-file batches; diagnose only failed batches."""
    results: list[dict[str, Any]] = []
    started = time.perf_counter()
    for batch_start in range(0, len(references), batch_size):
        batch = references[batch_start : batch_start + batch_size]
        batch_number = batch_start // batch_size
        tmp_parent = str(tmp_root) if tmp_root else None
        with tempfile.TemporaryDirectory(prefix=f"jac_eval_batch_{batch_number}_", dir=tmp_parent) as tmp:
            cwd = Path(tmp)
            env = dict(os.environ)
            if jac_tmp is not None:
                env["TMPDIR"] = str(jac_tmp)
            candidate_paths: list[str] = []
            guard_paths: list[str] = []
            for source_id, problem in batch:
                candidate_name = f"candidate_{source_id}.jac"
                guard_name = f"guard_{source_id}.jac"
                source = str(problem["idiomatic_jac"]).rstrip()
                (cwd / candidate_name).write_text(source + "\n", encoding="utf-8")
                (cwd / guard_name).write_text(
                    source
                    + "\n\n"
                    + str(problem["test_blocks"]).rstrip()
                    + "\n",
                    encoding="utf-8",
                )
                candidate_paths.append(candidate_name)
                guard_paths.append(guard_name)

            checked = eval_jac.run_process(
                [jac_bin, "check", *candidate_paths], cwd, batch_timeout_s, env
            )
            tested: eval_jac.ProcessResult | None = None
            if checked.returncode == 0 and not checked.timed_out and not checked.launch_error:
                tested = eval_jac.run_process(
                    [jac_bin, "test", *guard_paths], cwd, batch_timeout_s, env
                )

            batch_passed = (
                tested is not None
                and tested.returncode == 0
                and not tested.timed_out
                and not tested.launch_error
            )
            if batch_passed:
                for source_id, problem in batch:
                    source = str(problem["idiomatic_jac"])
                    diagnostics = eval_jac.static_diagnostics(source)
                    contract_pass, missing, forbidden = eval_jac.validate_contract(
                        problem, diagnostics["features"]
                    )
                    row: dict[str, Any] = {
                        "problem_id": problem["id"],
                        "sample_id": "reference",
                        "source_id": source_id,
                        "track": "function",
                        "status": "pass" if contract_pass else "contract_fail",
                        "check_pass": True,
                        "has_behavior_tests": True,
                        "test_executed": True,
                        "test_pass": True,
                        "contract_pass": contract_pass,
                        "task_success": contract_pass,
                        "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
                        "static": diagnostics,
                        "batch": batch_number,
                        "batch_check_ms": round(checked.elapsed_ms, 1),
                        "batch_test_ms": round(tested.elapsed_ms, 1),
                    }
                    if missing:
                        row["missing_features"] = missing
                    if forbidden:
                        row["forbidden_features_present"] = forbidden
                    results.append(row)
            else:
                failed_process = checked if tested is None else tested
                if failed_process.launch_error or eval_jac.is_infra_failure(failed_process):
                    status = "infra_error"
                    task_success: bool | None = None
                    test_pass: bool | None = None
                elif failed_process.timed_out:
                    status = "timeout"
                    task_success = False
                    test_pass = False
                elif failed_process.returncode is None or failed_process.returncode < 0:
                    status = "tool_crash"
                    task_success = False
                    test_pass = False
                else:
                    # A genuine compiler/test failure may affect one source only.
                    # Fall back to serial grading for this batch to identify it.
                    diagnosed = validate_references(
                        batch,
                        jac_bin=jac_bin,
                        workers=1,
                        timeout_s=fallback_timeout_s,
                        tmp_root=tmp_root,
                        jac_tmp=jac_tmp,
                    )
                    for row in diagnosed:
                        row["batch"] = batch_number
                        row["batch_fallback"] = True
                    results.extend(diagnosed)
                    status = ""
                    task_success = None
                    test_pass = None

                if status:
                    error = (
                        failed_process.launch_error
                        or (
                            eval_jac.infra_excerpt(failed_process)
                            if status == "infra_error"
                            else eval_jac.concise_output(failed_process)
                        )
                    )
                    for source_id, problem in batch:
                        results.append(
                            {
                                "problem_id": problem["id"],
                                "sample_id": "reference",
                                "source_id": source_id,
                                "track": "function",
                                "status": status,
                                "stage": "check" if tested is None else "test",
                                "check_pass": tested is not None,
                                "has_behavior_tests": True,
                                "test_executed": tested is not None,
                                "test_pass": test_pass,
                                "contract_pass": None,
                                "task_success": task_success,
                                "batch": batch_number,
                                "returncode": failed_process.returncode,
                                "error": error,
                            }
                        )

        completed = min(batch_start + len(batch), len(references))
        elapsed = max(time.perf_counter() - started, 0.001)
        statuses = Counter(str(row["status"]) for row in results)
        print(
            f"validated {completed}/{len(references)} in batches "
            f"({completed/elapsed:.2f}/s) statuses={dict(statuses)}",
            flush=True,
        )
    order = {source_id: index for index, (source_id, _) in enumerate(references)}
    results.sort(key=lambda row: order[int(row["source_id"])])
    return results


def write_report(
    report_dir: Path,
    results: list[dict[str, Any]],
    *,
    eval_dir: Path,
    manifest: dict[str, Any],
    jac_bin: str,
    timeout_s: float,
    workers: int,
    batch_size: int,
    batch_timeout_s: float,
) -> dict[str, Any]:
    if report_dir.exists():
        raise FileExistsError(f"report directory already exists: {report_dir}")
    report_dir.mkdir(parents=True)
    eval_jac_results = report_dir / "results.jsonl"
    builder.write_jsonl(eval_jac_results, results)
    status_counts = Counter(str(row["status"]) for row in results)
    passed = sum(row.get("task_success") is True for row in results)
    infra_errors = status_counts.get("infra_error", 0)
    failed_source_ids = sorted(
        int(row["source_id"])
        for row in results
        if row.get("task_success") is False
    )
    infra_source_ids = sorted(
        int(row["source_id"])
        for row in results
        if row.get("status") == "infra_error"
    )
    (report_dir / "failed_source_ids.txt").write_text(
        "".join(f"{source_id}\n" for source_id in failed_source_ids), encoding="utf-8"
    )
    (report_dir / "infra_source_ids.txt").write_text(
        "".join(f"{source_id}\n" for source_id in infra_source_ids), encoding="utf-8"
    )
    summary = {
        "schema_version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "eval_dir": str(eval_dir),
        "composer_sha256": manifest["composer_snapshot"]["sha256"],
        "jac_version": eval_jac.jac_version(jac_bin),
        "configuration": {
            "jac_bin": jac_bin,
            "fallback_timeout_s": timeout_s,
            "fallback_workers": workers,
            "batch_size": batch_size,
            "batch_timeout_s": batch_timeout_s,
        },
        "sources": len(results),
        "passed": passed,
        "failed": len(failed_source_ids),
        "infra_errors": infra_errors,
        "failed_source_ids": failed_source_ids,
        "infra_source_ids": infra_source_ids,
        "status_counts": dict(sorted(status_counts.items())),
        "all_passed": passed == len(results),
    }
    (report_dir / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return summary


def seal(eval_dir: Path, manifest: dict[str, Any], report_dir: Path, summary: dict[str, Any]) -> None:
    validation_target = eval_dir / "validation"
    if validation_target.exists():
        raise FileExistsError(f"validation target already exists: {validation_target}")
    report_dir.rename(validation_target)
    (eval_dir / "SEALED").write_text(
        "Function Jac evaluation suite sealed after full reference validation.\n",
        encoding="utf-8",
    )
    manifest["status"] = "sealed"
    manifest["sealed_at"] = datetime.now(timezone.utc).isoformat()
    manifest["validation"] = {
        "sources": summary["sources"],
        "passed": summary["passed"],
        "jac_version": summary["jac_version"],
        "summary_sha256": builder.sha256_file(validation_target / "summary.json"),
        "results_sha256": builder.sha256_file(validation_target / "results.jsonl"),
    }
    manifest["files"] = builder.file_manifest(eval_dir)
    temporary = eval_dir / ".manifest.json.tmp"
    temporary.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    temporary.replace(eval_dir / "manifest.json")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--eval-dir", type=Path, default=Path("evals/function/v1"))
    parser.add_argument("--split", choices=("all", "dev", "test"), default="all")
    parser.add_argument("--limit", type=int, default=0, help="smoke limit; never seals")
    parser.add_argument("--jac-bin", default="jac")
    parser.add_argument("--workers", type=int, default=1, help="per-source fallback workers")
    parser.add_argument("--timeout", type=float, default=180.0, help="per-source fallback timeout")
    parser.add_argument("--batch-size", type=int, default=25)
    parser.add_argument("--batch-timeout", type=float, default=900.0)
    parser.add_argument("--tmp-root", type=Path)
    parser.add_argument("--jac-tmp", type=Path)
    parser.add_argument(
        "--report-dir",
        type=Path,
        help="full-run staging report (default: <eval-dir>-validation)",
    )
    args = parser.parse_args()

    if (
        args.workers <= 0
        or args.timeout <= 0
        or args.batch_size <= 0
        or args.batch_timeout <= 0
        or args.limit < 0
    ):
        parser.error("worker/time/batch values must be positive and limit non-negative")
    manifest_path = args.eval_dir / "manifest.json"
    if not manifest_path.exists():
        print(f"error: missing {manifest_path}", file=sys.stderr)
        return 2
    manifest = json.loads(manifest_path.read_text())
    try:
        verify_manifest_files(args.eval_dir, manifest)
    except ValueError as exc:
        print(f"error: integrity check failed: {exc}", file=sys.stderr)
        return 2

    if manifest.get("status") == "sealed":
        print(f"{args.eval_dir} is sealed and all file hashes match")
        return 0
    if manifest.get("status") != "candidate_unvalidated":
        print(f"error: unsupported manifest status {manifest.get('status')!r}", file=sys.stderr)
        return 2

    splits = ["dev", "test"] if args.split == "all" else [args.split]
    try:
        _, reference_map = load_and_verify_tasks(args.eval_dir, splits)
    except ValueError as exc:
        print(f"error: task integrity check failed: {exc}", file=sys.stderr)
        return 2
    references = sorted(reference_map.items())
    if args.limit:
        references = references[: args.limit]
    if args.tmp_root:
        args.tmp_root.mkdir(parents=True, exist_ok=True)
    if args.jac_tmp:
        args.jac_tmp.mkdir(parents=True, exist_ok=True)

    print(
        f"validating {len(references)} unique references: split={args.split} "
        f"batch_size={args.batch_size} batch_timeout={args.batch_timeout}s",
        flush=True,
    )
    results = validate_reference_batches(
        references,
        jac_bin=args.jac_bin,
        batch_size=args.batch_size,
        batch_timeout_s=args.batch_timeout,
        fallback_timeout_s=args.timeout,
        tmp_root=args.tmp_root,
        jac_tmp=args.jac_tmp,
    )

    full_run = args.split == "all" and not args.limit
    if not full_run:
        summary = eval_jac.aggregate(results, [1])
        print(json.dumps(summary, indent=2, sort_keys=True))
        failures = [row for row in results if row.get("task_success") is not True]
        for row in failures[:25]:
            error = " ".join(str(row.get("error", "")).split())[:240]
            print(
                f"  source={row.get('source_id')} status={row.get('status')} "
                f"stage={row.get('stage', '-')} error={error}"
            )
        if args.report_dir:
            try:
                report = write_report(
                    args.report_dir,
                    results,
                    eval_dir=args.eval_dir,
                    manifest=manifest,
                    jac_bin=args.jac_bin,
                    timeout_s=args.timeout,
                    workers=args.workers,
                    batch_size=args.batch_size,
                    batch_timeout_s=args.batch_timeout,
                )
                print(f"wrote partial validation report: {args.report_dir}")
                print(f"partial all_passed={report['all_passed']}")
            except FileExistsError as exc:
                print(f"error: {exc}", file=sys.stderr)
                return 2
        print("partial/smoke validation: candidate was not modified or sealed")
        return 0 if not failures else 1

    report_dir = args.report_dir or args.eval_dir.with_name(args.eval_dir.name + "-validation")
    try:
        summary = write_report(
            report_dir,
            results,
            eval_dir=args.eval_dir,
            manifest=manifest,
            jac_bin=args.jac_bin,
            timeout_s=args.timeout,
            workers=args.workers,
            batch_size=args.batch_size,
            batch_timeout_s=args.batch_timeout,
        )
    except FileExistsError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(summary, indent=2, sort_keys=True))
    if not summary["all_passed"]:
        print(f"reference validation failed; candidate unchanged; report: {report_dir}")
        return 1

    seal(args.eval_dir, manifest, report_dir, summary)
    print(f"sealed {args.eval_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
