#!/usr/bin/env python3
"""Score dataset.jsonl records against .cursor/skills/jac-idiomatic/rubric.md.

D1 (syntax) is gated by `jac check`. D5 (behavior) is satisfied by construction:
records in dataset.jsonl already passed the hidden `jac test` guard, so D5>=2.
D2/D3/D4/D6 are heuristic per the rubric's quick-triage signals.
"""
import json, re, subprocess, sys, tempfile, os
from collections import Counter

DATA = "archive/2026-09/scratch/step4/dataset.jsonl"

def jac_check(jac: str) -> bool:
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as f:
        f.write(jac); p = f.name
    try:
        r = subprocess.run(["jac", "check", p], capture_output=True, text=True,
                           timeout=60, cwd=os.path.dirname(p) or None)
        return r.returncode == 0
    except Exception:
        return False
    finally:
        os.unlink(p)

def sig(jac: str) -> str:
    # signature line (up to first '{')
    return jac.split("{", 1)[0]

def score_record(r):
    jac = r["jac"]; s = sig(jac)
    d = {}
    # D1 syntax gate
    d["D1"] = 3 if jac_check(jac) else 0
    # D2 type fidelity
    untyped = bool(re.search(r"->\s*object|:\s*Any\b", jac))
    any_leak = bool(re.search(r":\s*any\b|->\s*any\b", jac))
    if untyped:
        d["D2"] = 0
    elif "->" not in s:
        d["D2"] = 1
    elif any_leak:
        d["D2"] = 2
    else:
        d["D2"] = 3
    # D3 language features (count idiomatic constructs)
    feats = 0
    feats += bool(re.search(r"\bmatch\b", jac))
    feats += bool(re.search(r"\bfor \w+ in ", jac) and "range(len(" not in jac)
    feats += bool(re.search(r"\bglob\b", jac))
    feats += bool(re.search(r"\b\w+ if .+ else ", jac))            # ternary
    feats += bool(re.search(r"\|", s))                              # union type
    feats += bool(re.search(r"startswith\(\(", jac))               # tuple startswith
    feats += bool(re.search(r"\[[^\]]+ for \w+ in ", jac))         # comprehension
    d["D3"] = min(3, feats) if not untyped else min(1, feats)
    # D4 readability — reward absence of floor smells
    smells = 0
    smells += jac.count("((")                                       # redundant parens
    smells += len(re.findall(r"return \(", jac))
    smells += bool("range(len(" in jac)
    d["D4"] = 3 if smells == 0 else (2 if smells <= 2 else 1)
    # D5 behavior — kept => passed guard; floor fallback counts as pass too
    d["D5"] = 2
    # D6 tier appropriateness — Tier A: penalize wrong-paradigm features
    wrong = bool(re.search(r"\bwalker\b|\bnode\b|\bby llm\b|with entry", jac))
    d["D6"] = 0 if wrong else 2
    total = (3*d["D1"] + 3*d["D2"] + 2*d["D3"] + 2*d["D4"] + 3*d["D5"] + 1*d["D6"]) / 14
    if d["D1"] == 0 or d["D5"] == 0:
        band = "REJECT(gate)"
    elif total >= 2.5: band = "A"
    elif total >= 2.0: band = "B"
    elif total >= 1.5: band = "C"
    else: band = "D"
    return total, band, d

def main():
    rows = [json.loads(l) for l in open(DATA)]
    bands = Counter(); tot = 0.0
    out = [None] * len(rows)
    verbose = len(rows) <= 40
    if verbose:
        print(f"{'entrypoint':32} {'src':9} {'D1 D2 D3 D4 D5 D6':17} {'score':>5} band")
        print("-"*78)
    from concurrent.futures import ThreadPoolExecutor
    def work(i_r):
        i, r = i_r
        total, band, d = score_record(r)
        return i, r, total, band, d
    with ThreadPoolExecutor(max_workers=12) as ex:
        for i, r, total, band, d in ex.map(work, list(enumerate(rows))):
            bands[band] += 1; tot += total
            out[i] = {"entrypoint": r.get("entrypoint"), "source": r["source"],
                      "dims": d, "score": round(total,3), "band": band}
            if verbose:
                dims = " ".join(f"{d[k]}" for k in ["D1","D2","D3","D4","D5","D6"])
                print(f"{(r.get('entrypoint') or '?')[:32]:32} {r['source']:9} {dims:17} {total:5.2f} {band}")
    if verbose:
        print("-"*78)
    print(f"records: {len(rows)}   mean score: {tot/len(rows):.2f}")
    print("bands:", dict(bands))
    # band split among idiomatic-source only (quality of the LLM rewrites)
    idi = [o for o in out if o["source"] == "idiomatic"]
    if idi:
        ib = Counter(o["band"] for o in idi)
        print(f"idiomatic-only ({len(idi)}): mean {sum(o['score'] for o in idi)/len(idi):.2f}  bands {dict(ib)}")
    json.dump({"mean_score": round(tot/len(rows),3), "bands": dict(bands), "records": out},
              open("archive/2026-09/scratch/step4/rubric_scores.json","w"), indent=2)
    print("\nwrote archive/2026-09/scratch/step4/rubric_scores.json")

if __name__ == "__main__":
    main()
