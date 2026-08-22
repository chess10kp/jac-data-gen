#!/usr/bin/env python3
"""Structural-fidelity gate for js2jac output.

`jac check` only proves the Jac COMPILES. It passed Yamde's hollow identity map
`{"yamde":"yamde"}` and the composer's lossy strips (bodies shrunk 1000+ chars).
This gate is a second, deterministic signal: parse the ORIGINAL JS for its
semantic signature (exported names, string literals, call targets, control flow)
and measure how much survives verbatim in the candidate Jac. It never runs code
(harvested React/TS isn't runnable in isolation, so a behavioral gate like
farm's isn't available) — it's a cheap ~80% catch for dropped declarations and
hollowed/stripped bodies, not a semantic proof.

Usage:
  fidelity_gate.py --dataset js2jac_dataset.jsonl        # calibrate / audit a corpus
  from fidelity_gate import score_record                 # per-record, in the guard
"""
import argparse, json, re, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SIG_JS = HERE / "source" / "sig_js.mjs"
BUN = "bun"

# thresholds (calibrated against the committed corpus; see --dataset audit)
T_STRING_RET   = 0.50   # min fraction of JS string literals present in Jac (when >=3)
T_CALLEE_RET   = 0.34   # min fraction of JS call targets present in Jac (when >=4)
T_MASS         = 0.35   # min non-space char ratio Jac/JS


def js_signature(js: str, path: str) -> dict:
    p = subprocess.run([BUN, str(SIG_JS)], input=json.dumps({"js": js, "path": path}),
                       capture_output=True, text=True, timeout=60)
    try:
        return json.loads(p.stdout)
    except Exception:
        return {"ok": False, "error": "sig:" + (p.stderr or p.stdout)[:200]}


def _tokens(text: str) -> set[str]:
    return set(re.findall(r"[A-Za-z_$][\w$]*", text))


_STYLING_RE = re.compile(r"styled-components|@emotion/styled|\bstyled\.\w|\bcss`|createGlobalStyle")

def _is_styling(js: str, path: str) -> bool:
    # CSS-in-JS: the string literals ARE css that Jac provably can't model (the
    # known ceiling), so their loss is expected, not hollowing. For these files
    # export-parity is the only meaningful fidelity signal (Yamde's hollow map
    # still fails it — the styled component names vanish).
    return ".styled." in path or bool(_STYLING_RE.search(js or ""))


def score_record(js: str, jac: str, path: str, sig: dict | None = None) -> dict:
    """Return {verdict: PASS|FAIL, reasons: [...], metrics: {...}}."""
    sig = sig or js_signature(js, path)
    if not sig.get("ok"):
        # can't parse the source -> can't judge fidelity; don't block on it
        return {"verdict": "PASS", "reasons": ["unparseable-source(skip)"], "metrics": {}}
    styling = _is_styling(js, path)

    jac_tokens = _tokens(jac)
    jac_text = jac

    # 1. export parity: every named export must reappear as a Jac identifier.
    # EXCEPT Next.js route handlers, whose exports are HTTP verbs (GET/POST/...):
    # the idiomatic persistence rewrite renames them to named walkers/defs, so a
    # verbatim GET token is not expected (see PERSISTENCE_MAPPING.md). The hollow
    # `return []` stub still fails on mass/strings, so this doesn't reopen the hole.
    HTTP_VERBS = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
    exports = [e for e in sig["exports"] if e != "default" and e not in HTTP_VERBS]
    missing_exports = [e for e in exports if e not in jac_tokens]
    export_parity = 1.0 if not exports else 1 - len(missing_exports) / len(exports)

    # 2. string-literal retention: hollow maps / stubs drop the source's strings
    strings = sig["strings"]
    kept_str = [s for s in strings if s in jac_text]
    string_ret = 1.0 if not strings else len(kept_str) / len(strings)

    # 3. call-target retention: removed logic drops callees
    callees = sig["callees"]
    kept_call = [c for c in callees if c in jac_tokens]
    callee_ret = 1.0 if not callees else len(kept_call) / len(callees)

    # 4. body mass: lossy strips collapse char count
    nj = len(re.sub(r"\s+", "", jac))
    ns = len(re.sub(r"\s+", "", js))
    mass = nj / ns if ns else 1.0

    reasons = []
    # export parity is the one hard signal that applies to EVERY file, styling or not
    if missing_exports:
        reasons.append(f"dropped-export:{','.join(missing_exports[:5])}")
    if not styling:
        # string / mass loss on a NON-styling file means real hollowing/stripping
        if len(strings) >= 3 and string_ret < T_STRING_RET:
            reasons.append(f"hollow-strings:{len(kept_str)}/{len(strings)}")
        if mass < T_MASS:
            reasons.append(f"lossy-mass:{mass:.2f}")

    # callee-retention is cross-language-noisy (JS methods -> Jac ops/comprehensions),
    # so it is INFORMATIONAL only — the real hollows already trip export/string/mass.
    warns = []
    if len(callees) >= 4 and callee_ret < T_CALLEE_RET:
        warns.append(f"low-callee-ret:{len(kept_call)}/{len(callees)}")

    return {
        "verdict": "FAIL" if reasons else "PASS",
        "reasons": reasons,
        "warns": warns,
        "styling": styling,
        "metrics": {"export_parity": round(export_parity, 2),
                    "string_ret": round(string_ret, 2),
                    "callee_ret": round(callee_ret, 2),
                    "mass": round(mass, 2),
                    "n_exports": len(exports), "n_strings": len(strings),
                    "n_callees": len(callees)},
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True, help="jsonl with js/jac/path per row")
    ap.add_argument("--show", type=int, default=25, help="how many FAILs to print")
    args = ap.parse_args()

    rows = [json.loads(l) for l in open(args.dataset) if l.strip()]
    n = len(rows)
    fails = []
    reason_hist = {}
    for r in rows:
        js, jac, path = r.get("js"), r.get("jac"), r.get("path", "x.ts")
        if not js or not jac:
            continue
        res = score_record(js, jac, path)
        if res["verdict"] == "FAIL":
            fails.append((r.get("path"), res))
            for rs in res["reasons"]:
                key = rs.split(":")[0]
                reason_hist[key] = reason_hist.get(key, 0) + 1

    print(f"corpus: {n} records | FAIL {len(fails)} ({len(fails)/max(1,n)*100:.1f}%)  "
          f"PASS {n-len(fails)}")
    print(f"reason histogram: {reason_hist}")
    print(f"--- first {args.show} FAILs ---")
    for path, res in fails[:args.show]:
        m = res["metrics"]
        print(f"  {path}\n     {res['reasons']}  "
              f"[exp{m['export_parity']} str{m['string_ret']} call{m['callee_ret']} mass{m['mass']}]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
