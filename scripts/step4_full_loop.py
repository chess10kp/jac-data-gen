#!/usr/bin/env python3
"""Step 4 full loop: py2jac -> idiomize -> guard -> keep|fallback -> jac fmt -> ROUGE-L dedup.

Completes the PLAN.md step-4 pipeline. Each record (coverage>=N), in an isolated
temp cwd:

    py2jac(content+tests)              -> floor jac        (drop on fail)
    jac test (floor + test blocks)     -> floor guard      (drop on fail)
    idiomatic = idiomize(floor, py)    -> [MODEL SEAM]     (mock = floor)
    jac test (idiomatic + test blocks) -> keep idiomatic | fall back to floor
    jac fmt(kept)                      -> normalized jac
    --> collect

Then a ROUGE-L near-duplicate pass (minhash-LSH blocked, so it scales) drops
duplicates. Emits dataset.jsonl + manifest.json with the full yield ladder:

    cov>=90 seen  ->  py2jac ok  ->  floor pass  ->  kept(idiomatic|floor)  ->  fmt  ->  dedup  ->  FINAL

The idiomize seam is ``idiomize()`` below. Default = mock (returns the floor),
so kept==floor and the idiomatic ratio is 0% — this run validates the plumbing
(fmt + dedup) end to end. Wire the real model by replacing idiomize() (use the
system prompt in scripts/step3_idiomize_prompt.md).

Usage:
    python scripts/step4_full_loop.py --limit 200 --workers 6            # mock
    python scripts/step4_full_loop.py --limit 200 --dedup-threshold 0.9
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

os.environ.setdefault("HF_HUB_OFFLINE", "1")

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "scripts"))
from step2_translate_tests import normalize_python, with_entry_to_tests  # noqa: E402
from idiomize_seam import (  # noqa: E402
    opencode_idiomize, zen_idiomize, zen_idiomize_k, idiom_score,
)
from step4_mutation import mutation_score  # noqa: E402

OUT_DIR = REPO / "data" / "step4"
DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"

# Mutation gate: below this kill-rate the floor test suite is too weak to police
# an idiomize swap, so we suppress the swap and keep the trusted floor. See
# scripts/step4_mutation.py. int/float cast is excluded as an equivalent mutant.
_MUTATION_GATE = 0.80

# idiomize mode config (set from CLI args in main)
_IDIOMIZE_MODE = "mock"     # mock | opencode | zen
_IDIOMIZE_MODEL = "deepseek-v4-flash-free"   # valid zen gateway id (see /models)
_IDIOMIZE_K = 5             # candidates to over-generate per record (zen only)


# --------------------------------------------------------------------------- #
# MODEL SEAM — dispatch on _IDIOMIZE_MODE. Returns a LIST of candidates so the
# guard can oracle-filter and the selector can pick the most idiomatic passer
# (MultiPL-T over-generate-and-filter; see idiomize_seam.zen_idiomize_k).
# --------------------------------------------------------------------------- #
def idiomize_candidates(floor_jac: str, python_src: str, entrypoint: str
                        ) -> tuple[list[str], float]:
    """Return (candidate_jac_list, total_latency_s). Empty list => keep floor.

    - mock: no candidates (validates plumbing; source stays floor).
    - zen: k diverse samples at temperature (the scalable path).
    - opencode: single candidate via the agent CLI (proofs only).
    """
    if _IDIOMIZE_MODE == "zen":
        return zen_idiomize_k(floor_jac, python_src, entrypoint,
                              k=_IDIOMIZE_K, model=_IDIOMIZE_MODEL)
    if _IDIOMIZE_MODE == "opencode":
        jac, dt = opencode_idiomize(floor_jac, python_src, entrypoint, _IDIOMIZE_MODEL)
        return ([jac] if jac else []), dt
    return [], 0.0  # mock


# --------------------------------------------------------------------------- #
def _run(cmd, cwd, env=None):
    # JAC_PROC_TIMEOUT: guard subprocess budget. Was hardcoded 120s, which a
    # wedged jac (e.g. corrupted embedded-Postgres codespace) silently turned
    # into candidate rejections -> floor fallback. 300s + a healed toolchain.
    to = int(os.environ.get("JAC_PROC_TIMEOUT", "300"))
    p = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=to,
                       env=env)
    return p.returncode, p.stdout, p.stderr


def jac_fmt(jac_src: str, tmpd: Path, name: str, env=None) -> str:
    f = tmpd / f"{name}.jac"
    f.write_text(jac_src)
    rc, out, err = _run(["jac", "fmt", str(f)], str(tmpd), env=env)
    return f.read_text() if rc == 0 else jac_src  # fall back to unformatted on error


def split_floor_fn(floor_jac: str) -> str:
    """py2jac raw = <function> + 'with entry {...}'. Return the function part."""
    m = re.search(r"\nwith entry \{", floor_jac)
    return floor_jac[: m.start()].rstrip() if m else floor_jac.rstrip()


def process(record: dict) -> dict:
    rid = record["id"]
    r = {"id": rid, "entrypoint": record["entrypoint"], "coverage": record.get("coverage"),
         "stage": None, "source": None, "jac": None, "idiomize_ms": None}
    py_src = normalize_python(record["content"].rstrip() + "\n\n"
                              + "\n".join(record["tests"]) + "\n")
    test_blocks = None  # built from floor below

    with tempfile.TemporaryDirectory(prefix=f"j4f_{rid}_") as tmp:
        tmpd = Path(tmp)
        work_py = tmpd / f"{rid}.py"; work_py.write_text(py_src)

        # 1. py2jac
        rc, out, err = _run(["jac", "tool", "py2jac", str(work_py)], tmp)
        if rc != 0:
            r["stage"] = "py2jac_fail"; r["error"] = (err or out)[-200:]; return r
        floor_jac = out

        # 2. floor guard
        guard = tmpd / f"{rid}.jac"
        guard.write_text(with_entry_to_tests(floor_jac))
        rc, out2, err2 = _run(["jac", "test", str(guard)], tmp)
        if rc != 0:
            r["stage"] = "test_fail"; r["error"] = (err2 or out2)[-200:]; return r
        r["stage"] = "floor_pass"

        # split floor function + test blocks for reuse
        floor_fn = split_floor_fn(floor_jac)
        test_blocks = with_entry_to_tests(floor_jac)
        test_blocks = test_blocks[len(floor_fn):].strip()  # the 'test "...' part

        # 2b. mutation gate — is the floor suite strong enough to POLICE a swap?
        #     A weak oracle can't catch an idiomize regression, so we suppress the
        #     swap and ship the trusted floor (which already passed its guard).
        #     Unscorable suites (no eligible mutants) fall through to keep-but-flag:
        #     we can't measure them, so we don't floor on no evidence.
        try:
            ms = mutation_score(floor_fn, test_blocks)
            if ms.eligible == 0:
                r["oracle_unscorable"] = True
            else:
                r["mutation_score"] = round(ms.score, 3)
                if ms.score < _MUTATION_GATE:
                    r["oracle_weak"] = True
                    r["mutation_survivors"] = ms.survivors[:5]
        except Exception as e:  # noqa: BLE001
            r["mutation_error"] = str(e)[:150]
            r["oracle_unscorable"] = True

        # 3. idiomize (seam) — over-generate k candidates.
        #    Skip entirely when the oracle is too weak to police a swap: keep the
        #    floor and don't spend idiomize API calls we can't safely accept.
        candidates: list[str] = []
        if not r.get("oracle_weak"):
            try:
                candidates, idiom_dt = idiomize_candidates(
                    floor_fn, record["content"], record["entrypoint"])
                r["idiomize_ms"] = round(idiom_dt * 1000, 1)
            except Exception as e:  # noqa: BLE001
                r["idiomize_error"] = str(e)[:150]
        r["n_candidates"] = len(candidates)

        # 4. oracle-filter every candidate; keep the most idiomatic passer.
        #    Quality = tests (the strong oracle); idiom_score is a FREE tiebreak
        #    over survivors, never a gate. No candidate passes -> fall back to floor.
        kept_fn, source = floor_fn, "floor"
        passers: list[str] = []
        last_err = None
        for i, cand in enumerate(candidates):
            if cand.strip() == floor_fn.strip():
                continue
            # 4a. static gate — `jac test` is runtime-only, so a candidate can be
            #     behaviorally correct yet not type-check (e.g. unnarrowed `match`
            #     guards -> E1032). Reject those before the runtime oracle so the
            #     dataset only carries statically-valid Jac.
            ccheck = tmpd / f"{rid}_cand{i}_chk.jac"
            ccheck.write_text(cand.rstrip() + "\n")
            rc_chk, o_chk, e_chk = _run(["jac", "check", str(ccheck)], tmp)
            if rc_chk != 0:
                last_err = "check: " + (e_chk or o_chk)[-140:]
                continue
            # 4b. runtime oracle
            cguard = tmpd / f"{rid}_cand{i}.jac"
            cguard.write_text(cand.rstrip() + "\n\n" + test_blocks + "\n")
            rc3, o3, e3 = _run(["jac", "test", str(cguard)], tmp)
            if rc3 == 0:
                passers.append(cand)
            else:
                last_err = (e3 or o3)[-150:]
        r["n_passers"] = len(passers)
        if passers:
            best = max(passers, key=lambda c: idiom_score(c, floor_fn))
            kept_fn, source = best, "idiomatic"
            r["idiom_score"] = round(idiom_score(best, floor_fn), 2)
        elif last_err:
            r["idiomatic_guard_error"] = last_err

        # 5. jac fmt
        r["jac"] = jac_fmt(kept_fn, tmpd, rid)
        r["source"] = source
        return r


# --------------------------------------------------------------------------- #
# ROUGE-L dedup (minhash-LSH blocked -> ROUGE-L confirm)
# --------------------------------------------------------------------------- #
_TOKEN = re.compile(r"\w+")


def tokens(s: str) -> list[str]:
    return _TOKEN.findall(s)


def shingles(toks: list[str], k: int = 4) -> set[str]:
    if len(toks) < k:
        return {" ".join(toks)} if toks else {""}
    return {" ".join(toks[i:i + k]) for i in range(len(toks) - k + 1)}


def minhash_sig(sh: set[str], n: int = 64) -> tuple[int, ...]:
    sig = []
    for i in range(n):
        h = min((int(hashlib.md5(f"{i}::{s}".encode()).hexdigest()[:15], 16) for s in sh),
                default=0)
        sig.append(h)
    return tuple(sig)


def lsh_candidates(sigs: dict, b: int = 32, r: int = 2) -> set:
    """Pairs that share at least one LSH band (over-recalls; ROUGE-L confirms)."""
    bands = defaultdict(list)
    for rid, sig in sigs.items():
        for band in range(b):
            bands[(band, sig[band * r:(band + 1) * r])].append(rid)
    cand = set()
    for members in bands.values():
        if len(members) > 1:
            members.sort()
            for i in range(len(members)):
                for j in range(i + 1, len(members)):
                    cand.add((members[i], members[j]))
    return cand


def lcs_len(a: list[str], b: list[str]) -> int:
    if len(a) < len(b):
        a, b = b, a
    prev = [0] * (len(b) + 1)
    for x in a:
        cur = [0] * (len(b) + 1)
        for j, y in enumerate(b, 1):
            cur[j] = prev[j - 1] + 1 if x == y else max(prev[j], cur[j - 1])
        prev = cur
    return prev[len(b)]


def rouge_l(a: list[str], b: list[str]) -> float:
    if not a or not b:
        return 0.0
    l = lcs_len(a, b)
    rec, prec = l / len(b), l / len(a)
    return 2 * rec * prec / (rec + prec) if rec + prec else 0.0


def dedup(records: list[dict], threshold: float) -> tuple[list[dict], int]:
    """Drop near-duplicates; keep the first (lowest id) of each cluster."""
    kept, dropped = [], 0
    toks = {r["id"]: tokens(r["jac"]) for r in records}
    sigs = {r["id"]: minhash_sig(shingles(toks[r["id"]])) for r in records}
    cands = lsh_candidates(sigs)
    # union-find over candidate pairs above threshold
    parent = {r["id"]: r["id"] for r in records}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x

    for a, b in cands:
        if rouge_l(toks[a], toks[b]) >= threshold:
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[max(ra, rb)] = min(ra, rb)  # keep lower id as root
    clusters = defaultdict(list)
    for r in records:
        clusters[find(r["id"])].append(r)
    for root, members in clusters.items():
        members.sort(key=lambda x: x["id"])
        kept.append(members[0])
        dropped += len(members) - 1
    kept.sort(key=lambda x: x["id"])
    return kept, dropped


# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=200)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--min-coverage", type=int, default=90)
    ap.add_argument("--workers", type=int, default=min(8, os.cpu_count() or 4))
    ap.add_argument("--idiomize", choices=["mock", "opencode", "zen"], default="mock",
                    help="zen = direct free opencode gateway (scalable); opencode = opencode run CLI (slow).")
    ap.add_argument("--model", default="deepseek-v4-flash-free",
                    help="zen gateway model id (see /models); default is the free deepseek.")
    ap.add_argument("--k", type=int, default=5,
                    help="candidates to over-generate per record (zen); keep the most idiomatic test-passer.")
    ap.add_argument("--dedup-threshold", type=float, default=0.9)
    ap.add_argument("--progress-every", type=int, default=50)
    args = ap.parse_args()
    global _IDIOMIZE_MODE, _IDIOMIZE_MODEL, _IDIOMIZE_K
    _IDIOMIZE_MODE, _IDIOMIZE_MODEL, _IDIOMIZE_K = args.idiomize, args.model, args.k

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")

    todo, seen = [], 0
    for record in ds:
        cov = record.get("coverage")
        if cov is None or cov < args.min_coverage:
            continue
        seen += 1
        if seen <= args.offset:
            continue
        if len(todo) >= args.limit:
            break
        todo.append(record)

    kdesc = f", k={args.k}" if args.idiomize == "zen" else ""
    print(f"Full loop on {len(todo)} records, {args.workers} workers, "
          f"idiomize={args.idiomize}{kdesc}, dedup@{args.dedup_threshold}", flush=True)
    results, t0 = [], time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(process, r): r for r in todo}
        for i, fut in enumerate(as_completed(futs), 1):
            try:
                results.append(fut.result())
            except Exception as e:  # noqa: BLE001
                r = futs[fut]; results.append({"id": r.get("id"), "stage": "crash", "error": str(e)[:150]})
            if i % args.progress_every == 0:
                kept = sum(1 for x in results if x.get("jac"))
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s, kept {kept}/{i}", flush=True)

    # dedup over kept (jac present)
    kept_records = [r for r in results if r.get("jac")]
    final, dedup_dropped = dedup(kept_records, args.dedup_threshold)
    for r in final:
        r["final"] = True

    elapsed = time.perf_counter() - t0
    manifest = build_manifest(results, final, dedup_dropped, elapsed, args)
    (OUT_DIR / "full_results.jsonl").write_text(
        "\n".join(json.dumps(r, default=str) for r in results) + "\n")
    (OUT_DIR / "dataset.jsonl").write_text(
        "\n".join(json.dumps({"id": r["id"], "entrypoint": r["entrypoint"],
                              "source": r["source"], "jac": r["jac"]}, default=str)
                  for r in final) + "\n")
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    write_report(manifest)
    print_summary(manifest)
    return 0


def build_manifest(results, final, dedup_dropped, elapsed, args):
    n = len(results)
    stage = Counter(r.get("stage") for r in results)
    sources = Counter(r.get("source") for r in final)
    idiom_ms = sorted(r["idiomize_ms"] for r in results if r.get("idiomize_ms"))
    import statistics as _st
    idiom_p50 = round(_st.quantiles(idiom_ms, n=100)[49], 1) if len(idiom_ms) >= 100 else (round(_st.mean(idiom_ms), 1) if idiom_ms else None)
    _cand = [r["n_candidates"] for r in results if r.get("n_candidates") is not None]
    _pass = [r["n_passers"] for r in results if r.get("n_passers") is not None]
    _scores = [r["idiom_score"] for r in results if r.get("idiom_score") is not None]
    _mscore = [r["mutation_score"] for r in results if r.get("mutation_score") is not None]
    _mean = lambda xs: round(_st.mean(xs), 2) if xs else None  # noqa: E731
    return {
        "min_coverage": args.min_coverage, "processed": n,
        "elapsed_s": round(elapsed, 1),
        "throughput_rec_per_s": round(n / elapsed, 2) if elapsed else None,
        "idiomize_mode": _IDIOMIZE_MODE,
        "idiomize_model": _IDIOMIZE_MODEL if _IDIOMIZE_MODE in ("opencode", "zen") else None,
        "idiomize_k": _IDIOMIZE_K if _IDIOMIZE_MODE == "zen" else None,
        "mean_candidates": _mean(_cand),
        "mean_passers": _mean(_pass),
        "mean_idiom_score": _mean(_scores),
        "dedup_threshold": args.dedup_threshold,
        "yield_ladder": {
            "py2jac_fail": stage.get("py2jac_fail", 0),
            "test_fail": stage.get("test_fail", 0),
            "floor_pass": stage.get("floor_pass", 0),
            "kept_after_idiomize_guard": len([r for r in results if r.get("jac")]),
            "final_after_dedup": len(final),
        },
        "source_split": {"idiomatic": sources.get("idiomatic", 0),
                         "floor": sources.get("floor", 0)},
        "mutation_gate": {
            "threshold": _MUTATION_GATE,
            "mean_score": _mean(_mscore),
            "oracle_weak": sum(1 for r in results if r.get("oracle_weak")),
            "oracle_unscorable": sum(1 for r in results if r.get("oracle_unscorable")),
        },
        "idiomize_ms_mean": idiom_p50,
        "dedup_dropped": dedup_dropped,
    }


def write_report(m):
    y = m["yield_ladder"]
    lines = [
        "# Step 4 full-loop report",
        "",
        f"**Date:** {time.strftime('%Y-%m-%d')}  ",
        f"**Idiomize mode:** `{m['idiomize_mode']}` (mock = returns floor)  ",
        f"**Dedup:** ROUGE-L @ {m['dedup_threshold']} (minhash-LSH blocked)  ",
        f"**Throughput:** {m['throughput_rec_per_s']} rec/s",
        "",
        "## Yield ladder (cov>=90 records)",
        "",
        f"| stage | count |", f"|-------|------:|",
        f"| processed | {m['processed']} |",
        f"| py2jac_fail (drop) | {y['py2jac_fail']} |",
        f"| test_fail (drop) | {y['test_fail']} |",
        f"| floor_pass | {y['floor_pass']} |",
        f"| kept (idiomatic or floor) | {y['kept_after_idiomize_guard']} |",
        f"| **final after dedup** | **{y['final_after_dedup']}** |",
        "",
        "## Source split of final",
        "", f"- idiomatic: {m['source_split']['idiomatic']}",
        f"- floor: {m['source_split']['floor']}",
        f"- dedup dropped: {m['dedup_dropped']}",
        "",
        "## Notes",
        "",
        "- With idiomize=mock, source split is 100% floor and idiomatic=0. The idiomatic "
        "ratio becomes the headline quality metric once the real model is wired into "
        "`idiomize()`.",
        "- This run validates the full plumbing (idiomize seam + keep/fallback + jac fmt "
        "+ ROUGE-L dedup) end to end.",
        "",
        "## Artifacts", "",
        "- `dataset.jsonl` — final deduped dataset ({id, entrypoint, source, jac})",
        "- `full_results.jsonl` — per-record stage + source",
        "- `manifest.json` — this yield ladder",
    ]
    (OUT_DIR / "FULL_REPORT.md").write_text("\n".join(lines) + "\n")


def print_summary(m):
    y = m["yield_ladder"]
    print(f"\n=== Yield ladder ({m['processed']} processed, idiomize={m['idiomize_mode']}) ===")
    print(f"  floor_pass {y['floor_pass']} -> kept {y['kept_after_idiomize_guard']}"
          f" -> final(dedup) {y['final_after_dedup']}  (dropped {m['dedup_dropped']} dups)")
    print(f"  source: idiomatic={m['source_split']['idiomatic']} floor={m['source_split']['floor']}")
    if m.get("idiomize_k"):
        print(f"  over-generate: k={m['idiomize_k']}, mean candidates={m['mean_candidates']}, "
              f"mean passers={m['mean_passers']}, mean idiom_score={m['mean_idiom_score']}")
    if m.get("idiomize_ms_mean"):
        print(f"  idiomize latency (mean/p50 ms): {m['idiomize_ms_mean']}")
    print(f"  throughput {m['throughput_rec_per_s']} rec/s")


if __name__ == "__main__":
    sys.exit(main())
