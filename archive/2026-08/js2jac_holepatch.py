#!/usr/bin/env python3
"""js2jac LLM hole-patch + re-gate loop.

Pipeline per record:
  1. convert JS -> Jac with hole-emission on (scaffold + `# JS2JAC-HOLE` markers)
  2. if it carries holes, ask an LLM (via `opencode run`) to fill them, translating
     the original JS at each hole into idiomatic Jac, emitting the COMPLETE file
  3. re-gate with `jac check` — keep only output that compiles

Measures the honest lift: baseline (sound converter alone) vs after-LLM, both by
whole-file `jac check`. The gate is the arbiter; the LLM only raises pre-gate yield.

Usage: python3 scripts/js2jac_holepatch.py [--limit N] [--model M] [--out FILE]
"""
from __future__ import annotations
import argparse, json, re, subprocess, sys, tempfile, time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BRIDGE_DRIVER = REPO / "scripts" / "js2jac_dataset" / "source" / "holeconvert.mjs"
DATASET = REPO / "scripts" / "js2jac_dataset" / "js2jac_dataset.jsonl"
FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)

RULES = """You are an expert Jac (Jaseci Labs) engineer completing a partial JS->Jac conversion.
You are given the ORIGINAL JS/TS file and a PARTIAL Jac conversion. The Jac is correct
where present; it has gaps marked `# JS2JAC-HOLE[code]:` followed by `# | <original js>`.

YOUR JOB: replace every JS2JAC-HOLE block with idiomatic Jac that faithfully translates
the original JS shown in the `# |` lines. Output the COMPLETE Jac file with NO holes left.

HARD RULES (any violation discards your output):
1. OUTPUT VALID JAC ONLY. Jac uses braces { } for blocks and a semicolon ; after every
   statement — never Python colon+indentation. Keep the existing `def:pub NAME(...) -> T {`
   / `import from "..." {...}` / `glob ...` forms exactly.
2. Do NOT rename anything. Keep declaration names, param names, and types as-is.
3. Translate the held-out JS faithfully; if a construct genuinely has no Jac form
   (e.g. CSS-in-JS), lower it to the closest typed placeholder rather than leaving a hole.
4. Keep all the already-converted code unchanged.
5. Output ONLY one ```jac fenced block with the whole file. No prose, no holes, no comments
   of the form JS2JAC-HOLE.
"""


def hole_convert(js: str, path: str) -> dict:
    p = subprocess.run(["bun", str(BRIDGE_DRIVER)], input=json.dumps({"js": js, "path": path}),
                       capture_output=True, text=True, timeout=60)
    try:
        return json.loads(p.stdout)
    except Exception:
        return {"ok": False, "error": "driver:" + p.stderr[:200]}


def jac_check(src: str) -> tuple[bool, str]:
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False, dir="/tmp") as f:
        f.write(src)
        fn = f.name
    try:
        p = subprocess.run(["jac", "check", fn], capture_output=True, text=True, timeout=90)
        out = p.stdout + p.stderr
        ok = p.returncode == 0 and "FAILED" not in out and "failed" not in out
        return ok, out
    finally:
        Path(fn).unlink(missing_ok=True)


def build_prompt(js: str, hole_jac: str, path: str) -> str:
    return (RULES + f"\n### ORIGINAL ({path})\n```\n{js}\n```\n\n"
            f"### PARTIAL JAC (fill the holes)\n```jac\n{hole_jac}\n```\n\n"
            "Output the complete idiomatic ```jac block (no holes).")


def llm_patch(prompt: str, model: str) -> str | None:
    try:
        p = subprocess.run(["opencode", "run", "-m", model, prompt],
                           capture_output=True, text=True, timeout=240)
    except subprocess.TimeoutExpired:
        return None
    m = FENCE.search(p.stdout)
    return m.group(1).strip() if m else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=15)
    ap.add_argument("--model", default="opencode/deepseek-v4-flash-free")
    ap.add_argument("--out", default=str(REPO / "data" / "holepatch_pilot.jsonl"))
    ap.add_argument("--input", default=str(DATASET), help="jsonl of {js, path} records")
    args = ap.parse_args()

    recs = [json.loads(l) for l in Path(args.input).read_text().splitlines() if l.strip()]
    outp = Path(args.out)
    outp.parent.mkdir(parents=True, exist_ok=True)
    results = []
    n_hole = 0
    stats = {"records": 0, "hole_carrying": 0, "baseline_pass": 0, "llm_attempted": 0,
             "llm_pass": 0, "llm_no_output": 0, "llm_still_fail": 0}

    for rec in recs:
        if n_hole >= args.limit:
            break
        js, path = rec.get("js", ""), rec.get("path", "x.tsx")
        conv = hole_convert(js, path)
        if not conv.get("ok"):
            continue
        stats["records"] += 1
        hole_jac = conv["jac"]
        if conv.get("holeCount", 0) == 0:
            # already complete scaffold — count as baseline pass if it checks
            ok, _ = jac_check(hole_jac)
            if ok:
                stats["baseline_pass"] += 1
            continue
        # hole-carrying: this is where the LLM earns its keep
        n_hole += 1
        stats["hole_carrying"] += 1
        # baseline = does the holed file (holes are comments) check as-is?
        base_ok, _ = jac_check(hole_jac)
        if base_ok:
            stats["baseline_pass"] += 1
        stats["llm_attempted"] += 1
        t0 = time.perf_counter()
        patched = llm_patch(build_prompt(js, hole_jac, path), args.model)
        dt = round(time.perf_counter() - t0, 1)
        row = {"path": path, "holeCount": conv["holeCount"], "baseline_pass": base_ok, "secs": dt}
        if not patched:
            stats["llm_no_output"] += 1
            row["result"] = "no_output"
        else:
            ok, out = jac_check(patched)
            row["result"] = "pass" if ok else "fail"
            row["patched_len"] = len(patched)
            if ok:
                stats["llm_pass"] += 1
                row["patched"] = patched
            else:
                stats["llm_still_fail"] += 1
                row["errors"] = re.findall(r"error\[E\d+\][^\n]*", out)[:4]
        results.append(row)
        print(f"[{n_hole}/{args.limit}] {path} holes={conv['holeCount']} base={base_ok} "
              f"llm={row['result']} {dt}s", flush=True)

    outp.write_text("\n".join(json.dumps(r) for r in results) + "\n")
    print("\n=== SUMMARY ===")
    print(json.dumps(stats, indent=2))
    lift = stats["llm_pass"] - stats["baseline_pass"]
    print(f"LLM lift on hole-carrying files: baseline {stats['baseline_pass']} -> "
          f"after-LLM {stats['llm_pass']} (+{stats['llm_pass'] - stats['baseline_pass']})")
    print(f"results -> {outp}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
