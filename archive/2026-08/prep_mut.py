#!/usr/bin/env python3
"""Mutation-gated prep: the step4_full_loop step-2b gate, restored at scale.

The original designed method refused to idiomize a record whose hidden-test
suite cannot police a swap (mutation kill-rate < gate). The scaled agent path
(agent_idiomize_prep.py) silently dropped that gate — which is how the weak
late-offset recovery rows (rec_9000..rec_17000) entered the idiomatic corpus
(see PY2JAC_QUALITY_GRADIENT.md). This script re-runs prep WITH the gate:

    py2jac -> floor guard (jac test) -> mutation_score(floor, tests, gate)
      eligible == 0  -> oracle_unscorable  (keep; still eligible for composer)
      score  < gate  -> oracle_weak        (SKIP composer; floor row only)
      score >= gate  -> strong oracle      (composer as usual)

Semantics deliberately identical to step4_full_loop.process() step 2b.
Resume-safe: existing work/<id>.json files are skipped.
"""
from __future__ import annotations
import argparse, json, os, shutil, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
import step4_full_loop as S
from step4_mutation import mutation_score

DEFAULT_GATE = 0.80  # == step4_full_loop._MUTATION_GATE


def prep_one(record: dict, shared_tmp: str, gate: float) -> dict:
    try:
        return _prep_one(record, shared_tmp, gate)
    except Exception as e:  # noqa: BLE001  (py2jac/test hang or crash -> drop record)
        return {"id": record.get("id"), "entrypoint": record.get("entrypoint"),
                "coverage": record.get("coverage"), "stage": "prep_error",
                "error": f"{type(e).__name__}: {str(e)[:120]}"}


def _prep_one(record: dict, shared_tmp: str, gate: float) -> dict:
    rid = record["id"]
    out = {"id": rid, "entrypoint": record["entrypoint"],
           "coverage": record.get("coverage"), "stage": None}
    py_src = S.normalize_python(record["content"].rstrip() + "\n\n"
                                + "\n".join(record["tests"]) + "\n")
    # Embedded-PG socket lives at /tmp/jacpg-* of the LIVE PG process; any other
    # TMPDIR hides it and every jac test rejects (see memory id 751). Hard /tmp.
    tmpd = Path(tempfile.mkdtemp(prefix=f"pm_{rid}_", dir=shared_tmp))
    # JAC_TEST_JOBS=1: jac test defaults to parallel jobs, spawning per-core
    # worker processes (~200MB each) that OOM this box during mutation gates.
    env = {**os.environ, "TMPDIR": shared_tmp, "JAC_TEST_JOBS": "1"}
    try:
        (tmpd / f"{rid}.py").write_text(py_src)
        rc, o, e = S._run(["jac", "tool", "py2jac", str(tmpd / f"{rid}.py")],
                          str(tmpd), env=env)
        if rc != 0:
            out["stage"] = "py2jac_fail"; out["error"] = (e or o)[-200:]; return out
        floor_jac = o
        guard = tmpd / f"{rid}.jac"; guard.write_text(S.with_entry_to_tests(floor_jac))
        rc2, o2, e2 = S._run(["jac", "test", str(guard)], str(tmpd), env=env)
        if rc2 != 0:
            out["stage"] = "test_fail"; out["error"] = (e2 or o2)[-200:]; return out
        floor_fn = S.split_floor_fn(floor_jac)
        test_blocks = S.with_entry_to_tests(floor_jac)[len(floor_fn):].strip()
        out.update(stage="floor_pass", python=record["content"], floor_fn=floor_fn,
                   test_blocks=test_blocks)
        # --- step 2b: mutation gate (restored) ---------------------------- #
        try:
            ms = mutation_score(floor_fn, test_blocks, gate=gate, workers=4)
            if ms.eligible == 0:
                out["oracle_unscorable"] = True
            else:
                out["mutation_score"] = round(ms.score, 3)
                out["mutation_killed"] = ms.killed
                out["mutation_eligible"] = ms.eligible
                if ms.score < gate:
                    out["oracle_weak"] = True
                    out["mutation_survivors"] = ms.survivors[:5]
        except Exception as e:  # noqa: BLE001
            out["mutation_error"] = str(e)[:150]
            out["oracle_unscorable"] = True
        return out
    finally:
        shutil.rmtree(tmpd, ignore_errors=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--offset", type=int, required=True,
                    help="nth coverage>=min-coverage record to start at")
    ap.add_argument("--limit", type=int, default=2000)
    ap.add_argument("--min-coverage", type=int, default=90)
    ap.add_argument("--gate", type=float, default=DEFAULT_GATE)
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--shared-tmp", default="/tmp",
                    help="TMPDIR hosting the live embedded-PG socket (default /tmp)")
    args = ap.parse_args()

    work = Path(args.work_dir)
    work.mkdir(parents=True, exist_ok=True)
    os.makedirs(args.shared_tmp, exist_ok=True)

    from datasets import load_dataset
    ds = load_dataset(S.DATASET, split="train")
    todo, seen = [], 0
    for rec in ds:
        cov = rec.get("coverage")
        if cov is None or cov < args.min_coverage:
            continue
        seen += 1
        if seen <= args.offset:
            continue
        if len(todo) >= args.limit:
            break
        todo.append(rec)

    already = {int(p.stem) for p in work.glob("*.json")}
    todo = [r for r in todo if r["id"] not in already]
    print(f"[prep_mut off={args.offset} gate={args.gate}] {len(todo)} to prep "
          f"({len(already)} already on disk) -> {work}", flush=True)

    tallies: dict = {}
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(prep_one, r, args.shared_tmp, args.gate) for r in todo]
        for i, fut in enumerate(as_completed(futs), 1):
            r = fut.result()
            key = r.get("stage") or "?"
            tallies[key] = tallies.get(key, 0) + 1
            if r.get("oracle_weak"):
                tallies["oracle_weak"] = tallies.get("oracle_weak", 0) + 1
            if r.get("oracle_unscorable"):
                tallies["oracle_unscorable"] = tallies.get("oracle_unscorable", 0) + 1
            if r["stage"] == "floor_pass":
                (work / f"{r['id']}.json").write_text(json.dumps(r))
            if i % 50 == 0:
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s {tallies}",
                      flush=True)
    print(f"[prep_mut] done in {time.perf_counter()-t0:.0f}s: {tallies}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
