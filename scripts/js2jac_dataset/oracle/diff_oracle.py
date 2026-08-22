#!/usr/bin/env python3
"""js2jac differential oracle: keep a converted record only if its Jac output
reproduces the ORIGINAL JS behavior on model-invented, execution-locked cases.

Pipeline per record:
  1. model invents N concrete input cases (JSON args; NO expected values)
  2. run_cases.mjs executes the original JS -> locks {args -> actual output}
  3. convert JS -> Jac via the real converter bridge (holeconvert.mjs)
  4. emit `test` blocks asserting the locked pairs; `jac test` must pass
     (server codespace forced; same timeout-retry posture as the py side)
  5. mutation-score the locked suite over the converted floor (step4_mutation)

A test can only be written against ground truth produced by executing the
original, so the oracle verifies CROSS-LANGUAGE semantic fidelity — something
neither human tests nor model assertions provide here.

CLI:  python diff_oracle.py <record_id> [--cases 6] [--gate 0.8]
Deps: bun, jac on PATH; OPENCODE_KEY for case synthesis.
"""
from __future__ import annotations
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
sys.path.insert(0, str(REPO / "scripts" / "gen"))
from idiomize_seam import _opencode_key, ZEN_BASE  # noqa: E402
from step4_mutation import mutation_score  # noqa: E402

import httpx  # noqa: E402

HERE = Path(__file__).resolve().parent
CONVERT_MJS = HERE.parent / "source" / "holeconvert.mjs"
RUN_CASES_MJS = HERE / "run_cases.mjs"
_MODEL = os.environ.get("OXALPHA_SYNTH_MODEL", "x-preview-f-free")

# Only primitive/array/object-of-primitive returns can become Jac asserts today.
def _lockable(v: dict) -> bool:
    t = v.get("t")
    if t in ("num", "str", "bool"):
        return True
    if t == "arr":
        return all(_lockable(x) for x in v["v"])
    if t == "obj":
        return all(_lockable(x) for x in v["v"].values())
    return False


def _jac_literal(v: dict) -> str:
    t = v["t"]
    if t == "num":
        return repr(v["v"])
    if t == "bool":
        return "true" if v["v"] else "false"
    if t == "str":
        return '"' + v["v"].replace("\\", "\\\\").replace('"', '\\"') + '"'
    if t == "arr":
        return "[" + ", ".join(_jac_literal(x) for x in v["v"]) + "]"
    if t == "obj":
        pairs = ", ".join(
            f'"{k}": {_jac_literal(x)}' for k, x in sorted(v["v"].items()))
        return "{" + pairs + "}"
    raise ValueError(f"unlockable {t}")


def _arg_literal(a) -> str:
    if isinstance(a, bool):
        return "true" if a else "false"
    if isinstance(a, (int, float)):
        return repr(a)
    if isinstance(a, str):
        return '"' + a.replace('\\', '\\\\').replace('"', '\\"') + '"'
    if a is None:
        return 'null'
    raise ValueError(f"unsupported arg {a!r}")


def synthesize_cases(js: str, entry: str, n: int = 6,
                     temperature: float = 0.8) -> list[list]:
    """Model invents concrete argument lists. No expectations requested."""
    sys_p = ("You generate unit-test INPUT CASES for a JavaScript function. "
             "Output ONLY a JSON array of argument arrays, e.g. "
             '[[1, 2], ["a", null], []]. Rules: concrete literals only '
             "(numbers, strings, booleans, null, simple arrays); no functions, "
             "no objects with methods, no undefined; include edge cases "
             "(empty, single element, zero, negative, long input); exactly "
             f"{n} cases.")
    usr = (f"Function `{entry}`:\n```js\n{js}\n```\n"
           f"Output the JSON array of {n} argument arrays now.")
    last_err: str | None = None
    for attempt in range(3):
      try:
        r = httpx.post(f"{ZEN_BASE}/chat/completions",
                       headers={"Authorization": f"Bearer {_opencode_key()}",
                                "Content-Type": "application/json"},
                       json={"model": _MODEL, "max_tokens": 4096,
                             "temperature": temperature,
                             "messages": [{"role": "system", "content": sys_p},
                                          {"role": "user", "content": usr}]},
                       timeout=180)
        r.raise_for_status()
        text = r.json()["choices"][0]["message"]["content"] or ""
        m = re.search(r"\[.*\]", text, re.S)
        cases = json.loads(m.group(0))
        return [c for c in cases
                if isinstance(c, list) and all(
                    isinstance(a, (int, float, str, bool)) or a is None
                    for a in c)]
      except Exception as e:  # noqa: BLE001
        last_err = str(e)[:200]
    print(f"[case-gen] failed after retries: {last_err}", file=sys.stderr,
          flush=True)
    return []


def lock_ground_truth(js: str, entry: str, cases: list[list]) -> list[dict]:
    """Execute original in bun; return [{args, value}] for deterministic cases."""
    p = subprocess.run(["bun", str(RUN_CASES_MJS)],
                       input=json.dumps({"code": js, "entry": entry,
                                         "cases": [{"i": i, "args": a} for i, a in enumerate(cases)]}),
                       capture_output=True, text=True, timeout=60)
    out = json.loads(p.stdout)
    if not out.get("ok"):
        return []
    locked = []
    for r in out["results"]:
        if r["ok"] and _lockable(r["value"]):
            # determinism check: run twice, value must repeat identically
            locked.append({"args": cases[r["i"]], "value": r["value"]})
    det = []
    for c in locked:
        p2 = subprocess.run(["bun", str(RUN_CASES_MJS)],
                            input=json.dumps({"code": js, "entry": entry,
                                              "cases": [{"i": 0, "args": c["args"]}]}),
                            capture_output=True, text=True, timeout=60)
        o2 = json.loads(p2.stdout)
        if o2.get("ok") and o2["results"] and o2["results"][0]["ok"] \
                and o2["results"][0]["value"] == c["value"]:
            det.append(c)
    return det


def convert_to_jac(js: str, path: str) -> str | None:
    p = subprocess.run(["bun", str(CONVERT_MJS)],
                       input=json.dumps({"js": js, "path": path}),
                       capture_output=True, text=True, timeout=120)
    out = json.loads(p.stdout)
    if not out.get("ok") or not out.get("jac"):
        return None
    jac = out["jac"]
    if out.get("holeCount"):          # unconverted holes = unfaithful by construction
        return None
    return jac


def jac_test_passes(jac_src: str, test_blocks: str, rid: str) -> bool:
    safe = re.sub(r"[^\w-]", "_", str(rid))
    with tempfile.TemporaryDirectory(prefix=f"diff_{safe}_") as tmp:
        cfg = Path(tmp) / "jac.toml"
        cfg.write_text('[placement]\ndefault_codespace = "server"\n')
        gp = Path(tmp) / (re.sub(r"[^\w-]", "_", str(rid)) + ".jac")
        gp.write_text(jac_src.rstrip() + "\n\n" + test_blocks.strip() + "\n")
        rc = subprocess.run(["prlimit", "--as=${3<<30}".replace("${3<<30}", str(3 << 30)),
                             "--", "jac", "test", str(gp)],
                            capture_output=True, cwd=tmp, timeout=600).returncode
        return rc == 0


def build_test_blocks(entry: str, locked: list[dict]) -> str:
    blocks = []
    for i, c in enumerate(locked):
        args = ", ".join(_arg_literal(a) for a in c["args"])
        exp = _jac_literal(c["value"])
        blocks.append(f'test "d{i}" {{\n'
                      f'    assert ({entry}({args}) == {exp});;\n'
                      f'}}')
    return "\n\n".join(blocks)


def run_record(rec: dict, n_cases: int = 6, gate: float = 0.8
               ) -> dict | str:
    js, path = rec["js"], rec.get("path", "src.js")
    m = re.search(r"(?:export\s+)?(?:function|const)\s+([A-Za-z_$][\w$]*)", js)
    if not m:
        return "no_entry_found"
    entry = m.group(1)

    cases = synthesize_cases(js, entry, n_cases)
    if not cases:
        return "case_gen_fail"
    locked = lock_ground_truth(js, entry, cases)
    if not locked:
        return "no_deterministic_cases"

    jac_src = convert_to_jac(js, path)
    if not jac_src:
        return "convert_fail"

    blocks = build_test_blocks(entry, locked)
    if not jac_test_passes(jac_src, blocks, rec["id"]):
        return {"verdict": "behavior_drift", "cases_locked": len(locked),
                "entry": entry}

    ms = mutation_score(jac_src.split("test ")[0].rstrip(), blocks, workers=2)
    kept = ms.eligible > 0 and ms.score >= gate
    return {"verdict": "kept" if kept else "weak_oracle",
            "entry": entry, "cases_locked": len(locked),
            "mutation_score": round(ms.score, 3),
            "mutants_eligible": ms.eligible}


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("record_id")
    ap.add_argument("--cases", type=int, default=6)
    ap.add_argument("--gate", type=float, default=0.8)
    a = ap.parse_args()
    rows = (REPO / "scripts/js2jac_dataset/js2jac_dataset.jsonl").read_text().splitlines()
    rec = next(json.loads(l) for l in rows
               if json.loads(l)["id"] == a.record_id)
    print(json.dumps(run_record(rec, a.cases, a.gate), indent=2))
