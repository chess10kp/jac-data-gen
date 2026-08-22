#!/usr/bin/env python3
"""Phase 3 of the agent-idiomize path: guard subagent candidates -> dataset.

Reads prepared work (data/step4/agent_work/<id>.json) and subagent candidates
(data/step4/agent_candidates.jsonl: {id, candidate}). For each record, applies
the SAME guard as step4_full_loop:
  1. jac check on the candidate (static gate; skip floor which is untyped)
  2. jac test  on candidate + hidden test_blocks (runtime oracle)
Keep the candidate iff both pass, else fall back to the floor. Then jac fmt and
ROUGE-L dedup, and emit dataset.jsonl + manifest.
"""
from __future__ import annotations
import argparse, json, os, re, shutil, sys, tempfile, time
from pathlib import Path
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "lib"))
import jsonl_io
import step4_full_loop as S

WORK = S.OUT_DIR / "agent_work"

# --- output bans (enforced hard, not just prompted) ------------------------ #
# `any` as a type is forbidden: a concrete type always exists for these funcs.
_ANY_TYPE = re.compile(r"(?::\s*|->\s*|\[\s*|\|\s*|,\s*)any\b")
# Needless backtick-escapes on names that are NEVER Jac reserved keywords, so
# removing the backtick can never break valid code. `obj`/`type`/`edge` etc. are
# real keywords and are deliberately NOT stripped (their escape can be required).
_BAD_TICK = re.compile(r"`(list|dict|set|tuple|str|int|float|bool|bytes|switch)\b")


def enforce_bans(candidate: str) -> tuple[str, str | None]:
    """Return (cleaned_candidate, reject_reason). reject_reason set iff banned."""
    if _ANY_TYPE.search(candidate):
        return candidate, "ban: `any` type"
    return _BAD_TICK.sub(r"\1", candidate), None  # strip needless backticks


def guard_one(work: dict, candidate: str | None,
              shared_tmp: str | None = None) -> dict:
    """Guard one candidate. shared_tmp: ONE embedded Postgres for all jac calls
    in this process (initdb ~80s; sharing drops jac test to ~7-12s). Shard across
  multiple processes with disjoint shared_tmp dirs to avoid PG lock contention."""
    rid = work["id"]
    floor_fn, test_blocks = work["floor_fn"], work["test_blocks"]
    r = {"id": rid, "entrypoint": work["entrypoint"], "coverage": work.get("coverage"),
         "stage": "floor_pass", "source": "floor", "n_candidates": 0}
    kept = floor_fn
    env = {**os.environ, "TMPDIR": "/tmp"} if shared_tmp else None
    if shared_tmp and shared_tmp != "/tmp":
        # The embedded Postgres socket is at $TMPDIR/jacpg-* of the LIVE PG
        # process (default /tmp). Any other shared_tmp hides it -> jac thinks
        # PG is mid-shutdown, fails to restart it, and every jac test rejects
        # -> 0% flips. Hard-default to /tmp (see memory id 751).
        shared_tmp = "/tmp"
    if shared_tmp:
        tmpd = Path(tempfile.mkdtemp(prefix=f"g_{rid}_", dir=shared_tmp))
    else:
        tmpd = Path(tempfile.mkdtemp(prefix=f"g_{rid}_"))
    try:
        if candidate and candidate.strip() and candidate.strip() != floor_fn.strip():
            r["n_candidates"] = 1
            # Preserve the raw model attempt: a rejected rewrite is still the
            # `rejected` side of a floor DPO pair (chosen = the mechanical floor
            # that passes). Only the *label* was ever bad, never the record.
            attempt = candidate
            # Enforce output bans: reject `any`-typed rewrites; strip needless
            # backtick-escapes before the candidate ever reaches the guard.
            candidate, ban = enforce_bans(candidate)
            if ban:
                r["reject"] = ban
                r["rejected_candidate"] = attempt
                r["jac"] = S.jac_fmt(kept, tmpd, rid, env=env)
                return r
            # A bad idiomize rewrite can hang (non-terminating loop) or crash the
            # tool; any guard exception (incl. timeout) is a reject -> floor.
            try:
                chk = tmpd / f"{rid}_chk.jac"; chk.write_text(candidate.rstrip() + "\n")
                rcc, oc, ec = S._run(["jac", "check", str(chk)], str(tmpd), env=env)
                if rcc != 0:
                    r["reject"] = "check: " + (ec or oc)[-120:]
                else:
                    cg = tmpd / f"{rid}_c.jac"
                    cg.write_text(candidate.rstrip() + "\n\n" + test_blocks + "\n")
                    rct, ot, et = S._run(["jac", "test", str(cg)], str(tmpd), env=env)
                    if rct == 0:
                        kept, r["source"] = candidate, "idiomatic"
                    else:
                        r["reject"] = "test: " + (et or ot)[-120:]
                        r["rejected_candidate"] = attempt
                if rcc != 0:
                    r["rejected_candidate"] = attempt
            except Exception as e:  # noqa: BLE001  (timeout, tool crash -> floor)
                r["reject"] = f"guard_exc: {type(e).__name__}: {str(e)[:100]}"
                r["rejected_candidate"] = attempt
        # Final formatting is also fallible (jac fmt / jac check can hang on a
        # pathological input). Never let it crash the record: fall back to the
        # unformatted kept text on any exception.
        try:
            # Needless backticks also appear in the py2jac FLOOR (`list, `dict).
            # Strip them, re-verifying the de-ticked version still compiles.
            stripped = _BAD_TICK.sub(r"\1", kept)
            if stripped != kept:
                v = tmpd / f"{rid}_v.jac"; v.write_text(stripped.rstrip() + "\n")
                rcv, _, _ = S._run(["jac", "check", str(v)], str(tmpd), env=env)
                if rcv == 0:
                    kept = stripped
            r["jac"] = S.jac_fmt(kept, tmpd, rid, env=env)
        except Exception as e:  # noqa: BLE001  (fmt/check hang -> unformatted)
            r["fmt_error"] = f"{type(e).__name__}"
            r["jac"] = kept
        return r  # (kept unchanged on reject -> floor)
    finally:
        shutil.rmtree(tmpd, ignore_errors=True)


def main() -> int:
    global WORK
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", default=str(S.OUT_DIR / "agent_candidates.jsonl"))
    ap.add_argument("--dedup-threshold", type=float, default=0.9)
    ap.add_argument("--out", default=str(S.OUT_DIR / "dataset.jsonl"))
    ap.add_argument("--work-dir", default=str(WORK))
    ap.add_argument("--workers", type=int, default=12)
    ap.add_argument("--shared-tmp",
                    help="TMPDIR for embedded Postgres (default: $TMPDIR or fresh dir)")
    ap.add_argument("--checkpoint", default=None,
                    help="JSONL checkpoint; per-record results fsync'd as they "
                         "complete, skipped on restart. Default: <out>.ckpt.jsonl")
    args = ap.parse_args()
    WORK = Path(args.work_dir)

    cand = {}
    cpath = Path(args.candidates)
    if cpath.exists():
        for line in cpath.read_text().splitlines():
            if line.strip():
                d = json.loads(line); cand[d["id"]] = d.get("candidate")
    works = [json.loads(p.read_text()) for p in sorted(WORK.glob("*.json"))]
    shared_tmp = args.shared_tmp or os.environ.get("TMPDIR")
    cleanup_tmp = False
    if not shared_tmp:
        shared_tmp = tempfile.mkdtemp(prefix="guard_shared_")
        cleanup_tmp = True
    os.makedirs(shared_tmp, exist_ok=True)
    print(f"guarding {len(works)} records ({len(cand)} have candidates) "
          f"| shared_tmp={shared_tmp}", flush=True)

    # --- resume: per-record fsync'd checkpoint; a killed guard re-runs only
    # what it never finished (the 12h-silent-restart class of loss). --- #
    ckpt_path = Path(args.checkpoint or (str(args.out) + ".ckpt.jsonl"))
    done: dict = {}
    if ckpt_path.exists():
        for ok, obj in jsonl_io.read_tolerant(ckpt_path):
            if ok and isinstance(obj, dict) and "id" in obj:
                done[obj["id"]] = obj
    todo = [w for w in works if w["id"] not in done]
    print(f"  resume: {len(done)} checkpointed, {len(todo)} to guard", flush=True)

    results, t0 = list(done.values()), time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(guard_one, w, cand.get(w["id"]), shared_tmp): w for w in todo}
        for i, fut in enumerate(as_completed(futs), 1):
            try:
                r = fut.result()
            except Exception as e:  # noqa: BLE001 — one bad record never aborts the run
                w = futs[fut]
                r = {"id": w["id"], "entrypoint": w.get("entrypoint"),
                     "source": "floor", "jac": w.get("floor_fn"),
                     "reject": f"guard_future_exc: {type(e).__name__}: {str(e)[:100]}"}
            jsonl_io.append(ckpt_path, r)  # fsync'd checkpoint per record
            results.append(r)
            if i % 100 == 0:
                idi = sum(1 for r in results if r.get("source") == "idiomatic")
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s  idiomatic {idi}", flush=True)
    kept = [r for r in results if r.get("jac")]
    final, dropped = S.dedup(kept, args.dedup_threshold)
    split = Counter(r["source"] for r in final)
    floor_map = {w["id"]: w["floor_fn"] for w in works}

    def _row(r: dict) -> str:
        row = {"id": r["id"], "entrypoint": r["entrypoint"],
               "source": r["source"], "jac": r["jac"]}
        # DPO pairs, both directions (chosen = r["jac"], which always passes):
        #  - floor row: rejected = the model rewrite that FAILED the guard.
        #  - idiomatic row: rejected = the plain mechanical floor it beat.
        if r["source"] == "floor" and r.get("rejected_candidate"):
            row["rejected"] = r["rejected_candidate"]
            row["reject_reason"] = r.get("reject")
        elif r["source"] == "idiomatic":
            row["rejected"] = floor_map.get(r["id"])
        return json.dumps(row)

    jsonl_io.atomic_write(Path(args.out), [_row(r) for r in final])
    manifest = {"processed": len(works), "final": len(final),
                "dedup_dropped": dropped, "source_split": dict(split),
                "idiomatic_rate": round(split.get("idiomatic", 0) / max(1, len(final)), 3),
                "rejects": [r["reject"] for r in results if r.get("reject")][:20]}
    (Path(args.out).parent / (Path(args.out).stem + "_manifest.json")) \
        .write_text(json.dumps(manifest, indent=2))
    print(f"final {len(final)}  split {dict(split)}  idiomatic_rate {manifest['idiomatic_rate']}  dropped {dropped}")
    if cleanup_tmp:
        shutil.rmtree(shared_tmp, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
