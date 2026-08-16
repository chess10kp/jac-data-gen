#!/usr/bin/env python3
"""Idiomize one record via `opencode run` + deepseek. Standalone test helper.

Builds a Jac-anchored prompt (hard syntax rules + tiny few-shot), calls
``opencode run -m <model>``, extracts the fenced Jac, prints it + whether it
looks Jac-shaped. Used to validate the prompt before wiring into the batch.
"""
from __future__ import annotations
import json, re, subprocess, sys, time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SAMPLES = REPO / "data" / "samples" / "python_source_examples.json"
FENCE = re.compile(r"```jac\s*\n(.*?)```", re.S)

FEWSHOT = """### Example of the transformation (Jac in -> Jac out)
Floor:
```jac
def add(a: Any, b: Any) -> object {
    return (a + b);
}
```
Idiomatic:
```jac
def add(a: int, b: int) -> int {
    return a + b;
}
```
Note: braces and semicolons are KEPT (Jac), parens dropped, real types added, name unchanged.
"""

RULES = """You are an expert Jac (Jaseci Labs) engineer. Rewrite the mechanical py2jac
function into IDIOMATIC JAC. The input floor is ALREADY Jac.

HARD RULES (any violation discards your output):
1. OUTPUT VALID JAC ONLY. Jac uses braces { } for every block and a semicolon ;
   after every statement — EXACTLY like the floor. NEVER Python's colon-and-
   indentation. If your output has a `def ...():` with a colon, it is WRONG.
2. KEEP THE FUNCTION NAME EXACTLY — do NOT rename it, do NOT snake_case it.
   The hidden tests call it by its current name.
3. Identical behavior. Infer real types (replace Any/object), drop redundant
   parens, use snake_case for LOCALS only, iterate instead of indexing, name
   magic numbers, collapse or-chains with startswith(tuple).
4. Output ONLY one ```jac fenced block containing the function. No prose.
"""


def build_prompt(floor_fn: str, py: str, entry: str) -> str:
    return (RULES + "\n" + FEWSHOT +
            f"\n### Python (original)\n```python\n{py}\n```\n\n"
            f"### Jac (mechanical floor) — keep this syntax\n```jac\n{floor_fn}\n```\n\n"
            f"Output the idiomatic ```jac block for `{entry}` (name unchanged).")


def opencode_idiomize(floor_fn: str, py: str, entry: str, model: str) -> str | None:
    msg = build_prompt(floor_fn, py, entry)
    t0 = time.perf_counter()
    p = subprocess.run(["opencode", "run", "-m", model, msg],
                       capture_output=True, text=True, timeout=150)
    dt = time.perf_counter() - t0
    m = FENCE.search(p.stdout)
    jac = m.group(1).strip() if m else None
    return jac, dt, p.stdout


def looks_jac(s: str) -> bool:
    return bool(s) and " {" in s and s.rstrip().endswith("}")


def main():
    model = sys.argv[1] if len(sys.argv) > 1 else "deepseek/deepseek-chat"
    ids = [int(x) for x in sys.argv[2:]] or [207145, 295211]
    recs = {r["id"]: r for r in json.loads(SAMPLES.read_text())}
    for rid in ids:
        r = recs[rid]
        floor = (REPO / f"data/step2/jac/{rid}.jac").read_text()
        floor_fn = re.sub(r"\nwith entry \{.*", "", floor, flags=re.S).strip()
        jac, dt, raw = opencode_idiomize(floor_fn, r["content"], r["entrypoint"], model)
        name_ok = jac and f"def {r['entrypoint']}" in jac
        print(f"--- {rid} {r['entrypoint']} ({dt:.1f}s) ---")
        print(f"  jac-shaped: {looks_jac(jac)}  name_kept: {bool(name_ok)}")
        print(jac[:400] if jac else "NO FENCE: " + raw[:300])
        print()


if __name__ == "__main__":
    main()
