#!/usr/bin/env python3
"""One-off audit of osp_lifts manifest records."""
from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
BASE = REPO / "data" / "osp_lifts"
SKIP = {"issues_9.jsonl", "issues_12.jsonl"}
JAC_TEST_TIMEOUT = 120


def run(cmd: list[str], cwd: Path, timeout: int = 180) -> tuple[int, str, bool]:
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=timeout)
        out = (p.stdout + p.stderr)[-1500:]
        return p.returncode, out, False
    except subprocess.TimeoutExpired:
        return 124, "timeout", True


def validate_record(rec_dir: Path, rec: dict) -> dict:
    result = {
        "id": rec["id"],
        "floor_status": rec.get("floor_status"),
        "floor_file": rec.get("floor_file"),
        "missing": [],
        "ref_fail": None,
        "jac_check_fail": None,
        "jac_test_fail": None,
        "jac_test_timeout": False,
        "floor_fail": None,
        "path_mismatch": None,
        "pass": False,
    }

    src = BASE / rec["source_file"] if rec.get("source_file") else None
    cand = BASE / rec["candidate_file"]
    guard = BASE / rec["guard_file"]
    ref = src.with_name(src.stem + ".ref.py") if src else None

    paths = [("candidate", cand), ("guard", guard)]
    if src:
        paths.extend([("source", src), ("ref", ref)])
    for label, path in paths:
        if not path.exists():
            result["missing"].append(f"{label}:{path.name}")

    floor_claimed = rec.get("floor_file")
    if floor_claimed:
        floor = BASE / floor_claimed
        if not floor.exists():
            result["missing"].append(f"floor:{Path(floor_claimed).name}")
    elif rec.get("floor_status") == "generated":
        result["path_mismatch"] = "floor_status=generated but floor_file is null"

    # naming mismatch: stem consistency
    if src and src.exists():
        expected_stem = src.stem
        for key, path in [("candidate", cand), ("guard", guard)]:
            if path.exists() and not path.name.startswith(expected_stem):
                result["path_mismatch"] = (
                    f"{key} {path.name} does not match source stem {expected_stem}"
                )

    if result["missing"]:
        return result

    if src:
        rc, out, _ = run(["python3", str(ref)], rec_dir)
        if rc != 0:
            result["ref_fail"] = out[-400:].strip().replace("\n", " | ")
            return result

    rc, out, _ = run([JAC, "check", str(cand)], rec_dir)
    if rc != 0:
        result["jac_check_fail"] = out[-400:].strip().replace("\n", " | ")
        return result

    rc, out, timed_out = run([JAC, "test", str(guard)], rec_dir, timeout=JAC_TEST_TIMEOUT)
    if timed_out:
        result["jac_test_timeout"] = True
        result["jac_test_fail"] = "timeout (120s)"
        return result
    if rc != 0:
        result["jac_test_fail"] = out[-400:].strip().replace("\n", " | ")
        return result

    if floor_claimed and (BASE / floor_claimed).exists():
        rc, out, _ = run([JAC, "check", str(BASE / floor_claimed)], rec_dir)
        if rc != 0:
            result["floor_fail"] = out[-400:].strip().replace("\n", " | ")
            return result

    result["pass"] = True
    return result


def main() -> int:
    # Only issue manifests contain OSP records. Other top-level JSONL files
    # (cost ledgers, failure logs, and source pools) use different schemas.
    manifests = sorted(BASE.glob("issues_*.jsonl"))
    by_batch: dict[str, dict] = {}
    all_results: list[dict] = []
    floor_counter = Counter()
    fail_modes = Counter()

    for manifest in manifests:
        name = manifest.name
        if name in SKIP:
            continue
        batch = {"pass": 0, "fail": 0, "missing": 0, "records": []}
        for line in manifest.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            floor_counter[rec.get("floor_status", "unknown")] += 1
            r = validate_record(manifest.parent, rec)
            all_results.append({**r, "batch": name})
            batch["records"].append(r)
            if r["missing"]:
                batch["missing"] += 1
                batch["fail"] += 1
                fail_modes["missing_files"] += 1
            elif r["pass"]:
                batch["pass"] += 1
            else:
                batch["fail"] += 1
                if r["ref_fail"]:
                    fail_modes["ref_fail"] += 1
                elif r["jac_check_fail"]:
                    fail_modes["jac_check_fail"] += 1
                elif r["jac_test_timeout"]:
                    fail_modes["jac_test_timeout"] += 1
                elif r["jac_test_fail"]:
                    fail_modes["jac_test_fail"] += 1
                elif r["floor_fail"]:
                    fail_modes["floor_fail"] += 1
                elif r["path_mismatch"]:
                    fail_modes["path_mismatch"] += 1
        by_batch[name] = batch
        print(f"{name}: pass={batch['pass']} fail={batch['fail']} missing={batch['missing']}", flush=True)

    total = len(all_results)
    passed = sum(1 for r in all_results if r["pass"])
    report = {
        "total": total,
        "passed": passed,
        "failed": total - passed,
        "pass_rate": round(100 * passed / total, 1) if total else 0,
        "by_batch": by_batch,
        "floor_status": dict(floor_counter),
        "fail_modes": dict(fail_modes),
        "failures": [r for r in all_results if not r["pass"]],
    }
    out_path = BASE / "_audit_results.json"
    out_path.write_text(json.dumps(report, indent=2))
    print(f"\nTOTAL: {passed}/{total} pass ({report['pass_rate']}%)")
    print(f"floor_status: {dict(floor_counter)}")
    print(f"fail_modes: {dict(fail_modes)}")
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
