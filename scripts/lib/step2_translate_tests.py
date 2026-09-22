#!/usr/bin/env python3
"""Step 2: concat Python function + asserts, py2jac, convert to jac test blocks.

Usage:
  python scripts/step2_translate_tests.py data/samples/python_source_examples.json
  python scripts/step2_translate_tests.py --record-id 147075
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()

U_PREFIX = re.compile(r"\bu(['\"])")


def normalize_python(src: str) -> str:
    """Strip Python 2 ``u''`` / ``u\"\"`` prefixes (py2jac does not accept them)."""
    return U_PREFIX.sub(r"\1", src)


def record_to_python(record: dict) -> str:
    body = record["content"].rstrip() + "\n\n" + "\n".join(record["tests"]) + "\n"
    return normalize_python(body)


def with_entry_to_tests(jac_src: str) -> str:
    """Turn py2jac's trailing ``with entry { assert ... }`` into ``test`` blocks."""
    match = re.search(r"\nwith entry \{", jac_src)
    if not match:
        return jac_src

    func_part = jac_src[: match.start()].rstrip()
    inner = jac_src[match.start() :]
    inner = inner[inner.index("{") + 1 : inner.rindex("}")]

    stmts: list[str] = []
    cur = ""
    depth = 0
    for ch in inner:
        cur += ch
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == ";" and depth == 0:
            stmt = cur.strip()
            if stmt:
                stmts.append(stmt)
            cur = ""
    if cur.strip():
        stmts.append(cur.strip())

    tests = [f'test "t{i}" {{\n    {stmt};\n}}' for i, stmt in enumerate(stmts)]
    return func_part + "\n\n" + "\n\n".join(tests) + "\n"


def py2jac(python_src: str, work_py: Path) -> tuple[bool, str, str]:
    work_py.write_text(python_src)
    proc = subprocess.run(
        [JAC, "tool", "py2jac", str(work_py)],
        capture_output=True,
        text=True,
    )
    err = (proc.stderr or proc.stdout)[-2000:]
    return proc.returncode == 0, proc.stdout, err


def jac_test(jac_path: Path) -> tuple[bool, str]:
    proc = subprocess.run(
        [JAC, "test", str(jac_path)],
        capture_output=True,
        text=True,
    )
    return proc.returncode == 0, (proc.stdout + proc.stderr)[-2000:]


def translate_record(record: dict, out_dir: Path) -> dict:
    rid = record["id"]
    work_py = out_dir / "work" / f"{rid}.py"
    raw_jac = out_dir / "jac" / f"{rid}.jac"
    test_jac = out_dir / "jac_testfmt" / f"{rid}.jac"

    for sub in ("work", "jac", "jac_testfmt"):
        (out_dir / sub).mkdir(parents=True, exist_ok=True)

    py_src = record_to_python(record)
    ok, jac_out, err = py2jac(py_src, work_py)
    result = {
        "id": rid,
        "entrypoint": record["entrypoint"],
        "n_tests": len(record["tests"]),
        "coverage": record.get("coverage"),
        "py2jac_ok": ok,
        "jac_test_ok": None,
        "error": None,
    }
    if not ok:
        result["error"] = err
        return result

    raw_jac.write_text(jac_out)
    test_jac.write_text(with_entry_to_tests(jac_out))
    test_ok, test_tail = jac_test(test_jac)
    result["jac_test_ok"] = test_ok
    if not test_ok:
        result["error"] = test_tail
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "samples_json",
        nargs="?",
        default="data/samples/python_source_examples.json",
        type=Path,
    )
    parser.add_argument("--record-id", type=int, action="append", dest="ids")
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("archive/2026-09/scratch/step2"),
    )
    args = parser.parse_args()

    records = json.loads(args.samples_json.read_text())
    if args.ids:
        id_set = set(args.ids)
        records = [r for r in records if r["id"] in id_set]

    results = [translate_record(r, args.out_dir) for r in records]
    report_path = args.out_dir / "results_latest.json"
    report_path.write_text(json.dumps(results, indent=2) + "\n")

    passed = sum(1 for r in results if r.get("jac_test_ok"))
    print(f"{passed}/{len(results)} records: py2jac + jac test passed")
    for r in results:
        status = "PASS" if r.get("jac_test_ok") else "FAIL"
        print(f"  {r['id']} ({r['entrypoint']}): {status}")
        if r.get("error"):
            print(f"    {r['error'][:200]}")

    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
