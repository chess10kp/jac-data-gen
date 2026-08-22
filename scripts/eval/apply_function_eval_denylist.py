#!/usr/bin/env python3
"""Check or filter a training JSONL against a sealed function-eval denylist.

The denylist contains every MultiPL-T source ID in the AST clusters reserved by
an evaluation suite, not only IDs present in composer when the suite was built.
This makes the guard safe as composer grows.

Check-only CI mode (nonzero if leakage is present):
  python scripts/apply_function_eval_denylist.py \
      --eval-dir evals/function/v1 \
      --input data/training_candidate.jsonl \
      --check-only

Create a filtered training export (refuses to overwrite):
  python scripts/apply_function_eval_denylist.py \
      --eval-dir evals/function/v1 \
      --input data/composer_dataset.jsonl \
      --output data/train/composer_without_function_v1.jsonl

By default, only a sealed eval may control a training export. `--allow-unsealed`
is provided only for pipeline smoke tests.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_denylist(eval_dir: Path, allow_unsealed: bool) -> tuple[set[int], dict[str, Any]]:
    manifest_path = eval_dir / "manifest.json"
    if not manifest_path.exists():
        raise ValueError(f"missing eval manifest: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    status = manifest.get("status")
    if status != "sealed" and not allow_unsealed:
        raise ValueError(f"eval status is {status!r}; training guard requires a sealed eval")

    deny_path = eval_dir / "denylist_ids.txt"
    expected = manifest.get("files", {}).get("denylist_ids.txt", {})
    if not deny_path.exists() or not expected:
        raise ValueError("eval manifest does not cover denylist_ids.txt")
    if sha256_file(deny_path) != expected.get("sha256"):
        raise ValueError("denylist_ids.txt hash does not match eval manifest")
    try:
        denied = {
            int(line.strip())
            for line in deny_path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        }
    except ValueError as exc:
        raise ValueError("denylist_ids.txt contains a non-integer source ID") from exc
    if not denied:
        raise ValueError("denylist is empty")
    return denied, manifest


def record_source_id(row: dict[str, Any], line_no: int) -> int:
    value = row.get("source_id", row.get("id"))
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"training row {line_no} has no integer id/source_id") from exc


def scan_or_filter(
    input_path: Path,
    denied: set[int],
    output_path: Path | None,
) -> dict[str, Any]:
    total = 0
    kept = 0
    denied_rows = 0
    denied_ids: set[int] = set()
    temporary: Path | None = None
    output_handle = None
    if output_path is not None:
        if output_path.exists():
            raise FileExistsError(f"refusing to overwrite output: {output_path}")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        temporary = output_path.with_name(f".{output_path.name}.tmp-{os.getpid()}")
        if temporary.exists():
            temporary.unlink()
        output_handle = temporary.open("w", encoding="utf-8")

    try:
        with input_path.open(encoding="utf-8") as handle:
            for line_no, line in enumerate(handle, 1):
                if not line.strip():
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError as exc:
                    raise ValueError(f"{input_path}:{line_no}: invalid JSON: {exc}") from exc
                if not isinstance(row, dict):
                    raise ValueError(f"{input_path}:{line_no}: expected object")
                source_id = record_source_id(row, line_no)
                total += 1
                if source_id in denied:
                    denied_rows += 1
                    denied_ids.add(source_id)
                    continue
                kept += 1
                if output_handle is not None:
                    output_handle.write(line if line.endswith("\n") else line + "\n")
        if output_handle is not None:
            output_handle.flush()
            os.fsync(output_handle.fileno())
            output_handle.close()
            output_handle = None
            assert temporary is not None and output_path is not None
            temporary.replace(output_path)
    except BaseException:
        if output_handle is not None:
            output_handle.close()
        if temporary is not None:
            temporary.unlink(missing_ok=True)
        raise

    return {
        "input_rows": total,
        "kept_rows": kept,
        "denied_rows": denied_rows,
        "unique_denied_ids": len(denied_ids),
        "first_denied_ids": sorted(denied_ids)[:25],
    }


def write_export_manifest(
    output_path: Path,
    input_path: Path,
    eval_dir: Path,
    eval_manifest: dict[str, Any],
    counts: dict[str, Any],
) -> Path:
    manifest_path = output_path.with_suffix(output_path.suffix + ".manifest.json")
    if manifest_path.exists():
        output_path.unlink(missing_ok=True)
        raise FileExistsError(f"refusing to overwrite export manifest: {manifest_path}")
    payload = {
        "schema_version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "input": {
            "path": str(input_path),
            "sha256": sha256_file(input_path),
        },
        "output": {
            "path": str(output_path),
            "sha256": sha256_file(output_path),
        },
        "eval": {
            "path": str(eval_dir),
            "status": eval_manifest.get("status"),
            "composer_snapshot_sha256": eval_manifest.get("composer_snapshot", {}).get("sha256"),
            "denylist_sha256": eval_manifest.get("files", {}).get("denylist_ids.txt", {}).get("sha256"),
            "reserved_clusters": eval_manifest.get("counts", {}).get("reserved_clusters"),
        },
        "counts": counts,
    }
    temporary = manifest_path.with_name(f".{manifest_path.name}.tmp-{os.getpid()}")
    temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    temporary.replace(manifest_path)
    return manifest_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--eval-dir", type=Path, default=Path("evals/function/v1"))
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--allow-unsealed", action="store_true")
    args = parser.parse_args()

    if args.check_only and args.output:
        parser.error("--check-only cannot be combined with --output")
    if not args.check_only and not args.output:
        parser.error("provide --output or use --check-only")
    try:
        denied, manifest = load_denylist(args.eval_dir, args.allow_unsealed)
        counts = scan_or_filter(args.input, denied, args.output)
    except (FileExistsError, OSError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    print(json.dumps(counts, indent=2, sort_keys=True))
    if args.check_only:
        if counts["denied_rows"]:
            print("leakage detected: training candidate contains reserved eval source IDs")
            return 1
        print("no reserved eval source IDs found")
        return 0

    assert args.output is not None
    try:
        export_manifest = write_export_manifest(
            args.output, args.input, args.eval_dir, manifest, counts
        )
    except (FileExistsError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    print(f"wrote filtered training export: {args.output}")
    print(f"wrote provenance manifest: {export_manifest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
