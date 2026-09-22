#!/usr/bin/env python3
"""Step 3 guard: validate Pi-produced idiomatic Jac against the test suite.

In this step the **Pi agent is the idiomize model** (see
``scripts/step3_idiomize_prompt.md`` for the rules it applies). This script is
the deterministic guard half of the loop:

    archive/2026-09/scratch/step3/idiomatic/<id>.jac   (Pi's idiomatic rewrite, function only)
            +  step-2 test blocks   (already proven to pass against the floor)
            ->  jac test
            ->  keep idiomatic | fall back to the py2jac floor

The keep ratio is the headline quality metric for step 3. Per-record floor vs.
idiomatic diffs are written so the idiom win is inspectable, not just counted.

For step 4 (batch over the full 133k) the model call is reintroduced out of
band; this guard logic is reused unchanged.

Usage:
    python scripts/step3_idiomize.py                  # guard all 5 idiomatic files
    python scripts/step3_idiomize.py --record-id 147075
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SAMPLES = REPO / "data" / "samples" / "python_source_examples.json"
STEP2_DIR = REPO / "data" / "step2"
OUT_DIR = REPO / "data" / "step3"
IDIOM_DIR = OUT_DIR / "idiomatic"

TEST_SPLIT = re.compile(r"\n\s*\ntest \"")


@dataclass
class Record:
    id: int
    entrypoint: str
    floor_jac: str          # py2jac raw (function + with entry)
    floor_fn: str           # py2jac function body only (no tests)
    test_blocks: str        # the "test ..." blocks, reused from step 2


def load_record(record: dict) -> Record:
    rid = record["id"]
    floor_raw = (STEP2_DIR / "jac" / f"{rid}.jac").read_text()
    testfmt = (STEP2_DIR / "jac_testfmt" / f"{rid}.jac").read_text()
    # step 2 wrote: <floor function> + "\n\n" + <test blocks>
    parts = TEST_SPLIT.split(testfmt, maxsplit=1)
    test_blocks = 'test "' + parts[1] if len(parts) == 2 else ""
    # floor function only = everything before the trailing `with entry`
    we = re.search(r"\nwith entry \{", floor_raw)
    floor_fn = floor_raw[: we.start()].rstrip() if we else floor_raw.rstrip()
    return Record(
        id=rid,
        entrypoint=record["entrypoint"],
        floor_jac=floor_raw,
        floor_fn=floor_fn,
        test_blocks=test_blocks,
    )


def jac_test(jac_path: Path) -> tuple[bool, str]:
    proc = subprocess.run(
        ["jac", "test", str(jac_path)], capture_output=True, text=True,
        cwd=str(jac_path.parent),
    )
    return proc.returncode == 0, (proc.stdout + proc.stderr)[-1500:]


def guard_one(rec: Record) -> dict:
    idiomatic = IDIOM_DIR / f"{rec.id}.jac"
    result = {
        "id": rec.id,
        "entrypoint": rec.entrypoint,
        "kept_idiomatic": False,
        "reason": None,
    }
    if not idiomatic.exists():
        result["reason"] = f"no idiomatic file at {idiomatic.relative_to(REPO)}"
        return result

    jac_src = idiomatic.read_text()
    guard_jac = OUT_DIR / "guard" / f"{rec.id}.jac"
    guard_jac.parent.mkdir(parents=True, exist_ok=True)
    guard_jac.write_text(jac_src.rstrip() + "\n\n" + rec.test_blocks + "\n")

    passed, tail = jac_test(guard_jac)
    result["jac_test_ok"] = passed
    result["idiomatic_jac"] = jac_src
    result["floor_jac"] = rec.floor_fn
    if passed:
        result["kept_idiomatic"] = True
    else:
        last = [ln for ln in tail.splitlines() if ln.strip()][-1:]
        result["reason"] = "guard_failed: " + (last[0] if last else "no output")
    return result


def diff_lines(a: str, b: str) -> str:
    return "\n".join(
        difflib.unified_diff(
            a.splitlines(), b.splitlines(),
            fromfile="floor", tofile="idiomatic", lineterm="",
        )
    )


def write_report(results: list[dict]) -> None:
    kept = sum(1 for r in results if r["kept_idiomatic"])
    n = len(results)
    (OUT_DIR / "results_latest.json").write_text(json.dumps(results, indent=2) + "\n")

    lines = [
        "# Step 3 report: idiomize (py2jac floor -> idiomatic Jac)",
        "",
        f"**Date:** {time.strftime('%Y-%m-%d')}  ",
        f"**Idiomize model:** Pi agent (rules in `scripts/step3_idiomize_prompt.md`)  ",
        f"**Guard:** `jac test` against the record's step-2 test blocks (model never sees tests)  ",
        f"**Samples:** {n}  ",
        f"**Keep ratio (idiomatic passed guard):** {kept}/{n}",
        "",
        "## Per-record",
        "",
        "| ID | entrypoint | idiomatic kept | reason |",
        "|----|------------|----------------|--------|",
    ]
    for r in results:
        flag = "yes" if r["kept_idiomatic"] else "no (floor fallback)"
        lines.append(f"| {r['id']} | `{r['entrypoint']}` | {flag} | {r.get('reason') or ''} |")

    lines += ["", "## Floor vs. idiomatic diffs", ""]
    for r in results:
        lines += [
            f"### {r['id']} `{r['entrypoint']}` — {'KEPT' if r['kept_idiomatic'] else 'FALLBACK'}",
            "```diff",
            diff_lines(r["floor_jac"], r["idiomatic_jac"]),
            "```",
            "",
        ]
    (OUT_DIR / "REPORT.md").write_text("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--record-id", type=int, action="append", dest="ids")
    args = ap.parse_args()

    records_raw = json.loads(SAMPLES.read_text())
    if args.ids:
        want = set(args.ids)
        records_raw = [r for r in records_raw if r["id"] in want]

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    records = [load_record(r) for r in records_raw]
    results = [guard_one(r) for r in records]
    write_report(results)

    kept = sum(1 for r in results if r["kept_idiomatic"])
    print(f"\nKeep ratio: {kept}/{len(results)} idiomatic passed guard")
    for r in results:
        flag = "KEEP" if r["kept_idiomatic"] else "FALLBACK"
        print(f"  {r['id']:>7} {r['entrypoint']:<35} {flag}  {r.get('reason') or ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
