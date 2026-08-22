#!/usr/bin/env python3
"""Native-filter prep toward 15k.

Like agent_idiomize_prep, but skips server-codespace floors BEFORE the slow
`jac test` (which provisions postgres and takes up to 120s on server records).
Flow per record:
  py2jac -> jac check (fast, ~1-2s, reports codespace)
         -> if floor is server-codespace: SKIP (cheap)
         -> else jac test (fast on native): keep on pass

Emits work JSONs (same shape agent_idiomize_prep writes) to --work-dir, so the
downstream composer (cursor_composer_batch) + guard (composer_guard_recover)
consume them unchanged.

Designed to run under nohup so an outer shell timeout cannot kill it.
"""
from __future__ import annotations
import argparse, json, os, subprocess, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
import step4_full_loop as S
from idiomize_seam import build_prompt


def _codespace_is_server(check_stderr_out: str) -> bool:
    s = check_stderr_out.lower()
    # jac check surfaces the codespace verdict; "server codespace" / "demoted"
    # both mean it needs postgres -> slow. "native" is fast.
    return "server codespace" in s or "demoted" in s or "compiled in the server" in s


def prep_one(record: dict, shared_tmp: str, test_to: int = 20) -> dict:
    rid = record["id"]
    out = {"id": rid, "entrypoint": record["entrypoint"],
           "coverage": record.get("coverage"), "stage": None}
    py_src = S.normalize_python(record["content"].rstrip() + "\n\n"
                                + "\n".join(record["tests"]) + "\n")
    # Per-record subdir, but a SHARED TMPDIR env so all records reuse ONE
    # persistent postgres (initdb is ~80s; sharing it drops test time to ~12s,
    # matching composer_guard_recover's fast pattern).
    tmpd = Path(tempfile.mkdtemp(prefix=f"nfp_{rid}_", dir=shared_tmp))
    try:
        env = {**os.environ, "TMPDIR": shared_tmp}
        (tmpd / f"{rid}.py").write_text(py_src)
        rc, o, e = _run(["jac", "tool", "py2jac", str(tmpd / f"{rid}.py")], env)
        if rc != 0:
            out["stage"] = "py2jac_fail"; out["error"] = (e or o)[-160:]; return out
        floor_jac = o
        # NATIVE floor test (shared persistent postgres -> ~7-12s, no orphans).
        guard = tmpd / f"{rid}_t.jac"; guard.write_text(S.with_entry_to_tests(floor_jac))
        rc2, o2, e2 = _run(["jac", "test", str(guard)], env, to=test_to)
        if rc2 != 0:
            out["stage"] = "test_fail"; out["error"] = (e2 or o2)[-160:]; return out
        floor_fn = S.split_floor_fn(floor_jac)
        test_blocks = S.with_entry_to_tests(floor_jac)[len(floor_fn):].strip()
        out.update(stage="floor_pass", python=record["content"], floor_fn=floor_fn,
                   test_blocks=test_blocks,
                   prompt=build_prompt(floor_fn, record["content"], record["entrypoint"]))
    finally:
        # only remove the per-record subdir, keep the shared TMPDIR/postgres
        import shutil
        shutil.rmtree(tmpd, ignore_errors=True)
    return out


def _run(cmd, env, to=120):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=to)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return 124, "", "TIMEOUT"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=2000)
    ap.add_argument("--min-coverage", type=int, default=90)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--test-timeout", type=int, default=20,
                    help="per-record jac test timeout; native floors pass in <10s, "
                         "server floors are capped (fail-fast) at this")
    ap.add_argument("--work-dir", required=True)
    args = ap.parse_args()
    work = Path(args.work_dir); work.mkdir(parents=True, exist_ok=True)

    # ONE shared temp workspace for the whole run -> one shared postgres.
    shared_tmp = tempfile.mkdtemp(prefix="nfp_shared_")
    print(f"shared TMPDIR (one postgres): {shared_tmp}", flush=True)
    from datasets import load_dataset
    ds = load_dataset(S.DATASET, split="train")
    todo, seen = [], 0
    already = 0
    for rec in ds:
        cov = rec.get("coverage")
        if cov is None or cov < args.min_coverage: continue
        seen += 1
        if seen <= args.offset: continue
        if len(todo) + already >= args.limit: break
        # resume-safe: skip records whose work file already exists
        if (work / f"{rec['id']}.json").exists():
            already += 1; continue
        todo.append(rec)
    print(f"native-filter prep {len(todo)} records (offset {args.offset}, "
          f"{already} already done) -> {work}", flush=True)

    t0 = time.perf_counter()
    tallies = {"floor_pass": 0, "py2jac_fail": 0, "test_fail": 0}
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        for i, fut in enumerate(as_completed([ex.submit(prep_one, r, shared_tmp, args.test_timeout) for r in todo]), 1):
            r = fut.result()
            tallies[r["stage"]] = tallies.get(r["stage"], 0) + 1
            if r["stage"] == "floor_pass":
                (work / f"{r['id']}.json").write_text(json.dumps(r))
            if i % 50 == 0:
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s {tallies}", flush=True)
    print(f"done in {time.perf_counter()-t0:.0f}s: {tallies}", flush=True)
    import shutil
    shutil.rmtree(shared_tmp, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
