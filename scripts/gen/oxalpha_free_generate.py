#!/usr/bin/env python3
"""Data generation with idiomatization using cursor-cli (composer-2.5).

For each source record (coverage>=90, sequential from --offset):
  py2jac floor -> floor passes hidden tests -> cursor-cli idiomatic rewrite
  -> candidate passes same hidden tests -> keep.
Appends kept rows to the output jsonl with full provenance. Resumable via
--offset; skips rids already present in the output file.
"""
from __future__ import annotations
import argparse, json, os, re, shutil, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

os.environ.setdefault("HF_HUB_OFFLINE", "1")
REPO = Path(__file__).resolve().parents[2]
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))
from step2_translate_tests import normalize_python, with_entry_to_tests  # noqa: E402
from idiomize_seam import cursor_idiomize  # noqa: E402
from step4_mutation import mutation_score  # noqa: E402

DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"
MODEL = "composer-2.5"
# PY2JAC_QUALITY_GRADIENT.md: never trust a hidden suite that cannot kill
# semantics-breaking mutants of the known-correct floor as an idiomize oracle.
_MUTATION_GATE = 0.80
# Mutant budget per record. Kept at the calibration value (40) after the
# quality review; speed comes from the <3-test-block pre-filter instead.
_MUTANT_CAP = int(os.environ.get("OXALPHA_MUTANT_CAP", "40"))
CAP = f"--as={int(os.environ.get('JAC_RLIMIT_AS_GB', '3')) << 30}"
_TIMEOUT_RETRY = 600
# py2jac emits `list() (python-interop escape) for Python list(); in
# natively-lowered modules that pattern SIGSEGVs invoke_native_test
# (jaseci-labs/jac#8481). An empty-list literal is exactly [].
_BACKTICK_EMPTY_LIST = re.compile(r"`list\(\s*\)")


def _sanitize_floor(jac_src: str) -> str:
    """Rewrite py2jac's `list() interop escape to a plain [] literal."""
    return _BACKTICK_EMPTY_LIST.sub("[]", jac_src)


def _run(cmd, cwd, timeout=120):
    try:
        p = subprocess.run(["prlimit", CAP, "--", *cmd], capture_output=True,
                           text=True, cwd=cwd, timeout=timeout)
        return p.returncode, p.stdout
    except subprocess.TimeoutExpired:
        return 124, ""


_SERVER_CS_TOML = '[build]\ndefault_codespace = "server"\n'
# [placement] is the LEGACY section: dropped by the jac native rebuild
# (2026-08-31) — every floor test then attempted doomed native lowering and
# failed. [build] is the probe-verified key (docs/OSP_IDIOMIZE_TASK.md §2).


def jac_test(gp, tmp, timeout=120):
    """Run `jac test` with one long-budget retry on wall-clock timeout.
    Returns (rc, timed_out). A timeout under worker concurrency is
    environmental, not semantic: jac test slows 3-5x at workers=4
    (~25-30s solo -> 87-129s), so anything >=~35s solo blew the 120s cap
    and was miscounted as floor_test_fail/guard_fail (2026-08-21).

    Drops default_codespace="server" into the work dir: py2jac-derived
    modules nearly always fail native lowering (Any/Unknown types) and the
    doomed native attempt + recompile burned ~24s CPU per record
    (measured: 28s -> 4s user, 2026-08-21). Native execution itself is NOT
    faster for these tiny pure functions (7.1s vs 6.1s on rid=191475), so
    we just skip the attempt."""
    cfg = Path(tmp) / "jac.toml"
    if not cfg.exists():
        cfg.write_text(_SERVER_CS_TOML)
    rc, _ = _run(["jac", "test", str(gp)], tmp, timeout=timeout)
    if rc == 124:
        rc, _ = _run(["jac", "test", str(gp)], tmp, timeout=_TIMEOUT_RETRY)
        return rc, rc == 124
    return rc, False


def build_case(record):
    """py2jac + floor guard -> case dict or failure reason string."""
    rid = record["id"]
    py = normalize_python(record["content"].rstrip() + "\n\n"
                          + "\n".join(record["tests"]) + "\n")
    with tempfile.TemporaryDirectory(prefix=f"prep_{rid}_") as tmp:
        wp = Path(tmp) / f"{rid}.py"; wp.write_text(py)
        rc, out = _run(["jac", "tool", "py2jac", str(wp)], tmp)
        if rc == 124:
            rc, out = _run(["jac", "tool", "py2jac", str(wp)], tmp,
                           timeout=_TIMEOUT_RETRY)
        if rc != 0:
            return "py2jac_fail"
        floor = _sanitize_floor(out)
        gp = Path(tmp) / f"{rid}.jac"; gp.write_text(with_entry_to_tests(floor))
        rc, timed_out = jac_test(gp, tmp)
        if timed_out:
            return "floor_test_timeout"
        if rc != 0:
            return "floor_test_fail"
        m = re.search(r"\nwith entry \{", floor)
        floor_fn = floor[:m.start()].rstrip() if m else floor.rstrip()
        tb = with_entry_to_tests(floor)
        return {"rid": rid, "entry": record["entrypoint"],
                "python": normalize_python(record["content"]),
                "floor_fn": floor_fn, "test_blocks": tb[len(floor_fn):].strip()}


def has_explicit_return(jac: str) -> bool:
    """Reject implicit-last-expression endings (style uniformity with composer)."""
    return bool(re.search(r"\breturn\b", jac))


def guard(fn_jac, test_blocks, rid):
    with tempfile.TemporaryDirectory(prefix=f"g_{rid}_") as tmp:
        gp = Path(tmp) / f"{rid}.jac"
        gp.write_text(fn_jac.rstrip() + "\n\n" + test_blocks + "\n")
        rc, _ = jac_test(gp, tmp)
        return rc == 0


def _count_tests(test_blocks: str) -> int:
    return len(re.findall(r'^\s*test\b', test_blocks, flags=re.M))


def process(record, gate: float = _MUTATION_GATE, k: int = 1,
            use_synth: bool = True):
    t0 = time.perf_counter()
    c = build_case(record)
    if isinstance(c, str):
        return {"rid": record["id"], "status": c}

    # Oracle synthesis (scripts/oracle_synth.py): instead of rejecting records
    # whose human-written suite is thin/weak, grow the suite with generated,
    # floor-validated tests until the mutation gate clears. The floor is
    # known-correct, so any test passing against it has correct expectations.
    synth = {"rounds": 0, "added": 0}

    def strengthen() -> None:
        from oracle_synth import strengthen_oracle
        c["test_blocks"], r, a, _ = strengthen_oracle(
            c["floor_fn"], c["test_blocks"], c["entry"], c["python"],
            gate=gate)
        synth["rounds"] += r
        synth["added"] += a

    n_tests = _count_tests(c["test_blocks"])
    if n_tests < 3:
        if not use_synth:
            return {"rid": c["rid"], "status": "weak_oracle",
                    "mutation_score": None, "note": f"only {n_tests} test block(s)"}
        strengthen()
        n_tests = _count_tests(c["test_blocks"])
        if n_tests < 3:
            return {"rid": c["rid"], "status": "weak_oracle",
                    "mutation_score": None,
                    "note": f"still {n_tests} test block(s) after synth"}
    # Mutation gate. eligible==0 means we could not GENERATE any mutant
    # (string-heavy / pass-through functions) — the gate is uninformative,
    # not the suite weak: keep the record with mutation_score=null
    # ("mutation_unmeasurable": true) per decision 2026-08-21. Only a real
    # survivor (eligible>0, score<gate) rejects.
    ms = mutation_score(c["floor_fn"], c["test_blocks"], cap=_MUTANT_CAP,
                        workers=2)
    unmeasurable = ms.eligible == 0
    if not unmeasurable and ms.score < gate:
        if use_synth:
            strengthen()
            ms = mutation_score(c["floor_fn"], c["test_blocks"],
                                cap=_MUTANT_CAP, workers=2)
            unmeasurable = ms.eligible == 0
        if not unmeasurable and ms.score < gate:
            return {"rid": c["rid"], "status": "weak_oracle",
                    "mutation_score": round(ms.score, 3)}
    # Sequential over-generation: sample, guard, stop at first pass.
    # Retry temperature raised for diversity; attempts only spent on
    # gate-qualified records (advisory: gpt-5.6-sol, option C).
    last_status, lat = "no_response", 0.0
    for attempt in range(k):
        temp = None if attempt == 0 else 0.8
        jac, dt = cursor_idiomize(c["floor_fn"], c["python"], c["entry"],
                               model=MODEL)
        lat += dt
        if jac is None:
            last_status = "no_response"
            continue
        if f"def {c['entry']}" not in jac:
            last_status = "renamed"
            continue
        if not has_explicit_return(jac):
            last_status = "implicit_return"
            continue
        if not guard(jac, c["test_blocks"], c["rid"]):
            last_status = "guard_fail"
            continue
        return {"rid": c["rid"], "status": "kept", "latency": round(lat, 1),
                "row": {"id": c["rid"], "entrypoint": c["entry"],
                        "floor_fn": c["floor_fn"], "candidate": jac,
                        "source": "idiomatic", "model": MODEL,
                        "mutation_score": (None if unmeasurable
                                           else round(ms.score, 3)),
                        "mutation_unmeasurable": unmeasurable,
                        "mutants_killed": None if unmeasurable else ms.killed,
                        "mutants_eligible": ms.eligible,
                        **({"oracle_synth_rounds": synth["rounds"],
                            "oracle_synth_tests": synth["added"]}
                           if synth["added"] else {}),
                        "attempts": attempt + 1}}
    return {"rid": c["rid"], "status": last_status, "latency": round(lat, 1)}


def disk_free_gb() -> float:
    return shutil.disk_usage(str(REPO)).free / 1e9


def cleanup_between_chunks(min_free_gb: float, force: bool = False) -> str:
    """Postgres leak control (safeguard 4): wiper first; if still tight, take
    the cluster offline between chunks (no jac processes are live here) and
    wipe so the next chunk bootstraps a fresh one."""
    subprocess.run([str(REPO / "scripts/ops/pg_cache_wiper.sh")], check=False)
    if not force and disk_free_gb() >= min_free_gb:
        return "ok"
    subprocess.run(["pkill", "-u", os.environ.get("USER", "jac"), "-x", "postgres"],
                   check=False)
    time.sleep(3)
    subprocess.run(["pkill", "-9", "-u", os.environ.get("USER", "jac"), "-x", "postgres"],
                   check=False)
    time.sleep(2)
    shutil.rmtree(Path.home() / ".cache/jac/pg", ignore_errors=True)
    for sock in Path("/tmp").glob("jacpg-*"):
        shutil.rmtree(sock, ignore_errors=True)
    time.sleep(1)
    return f"wiped (free={disk_free_gb():.0f}GB)"


def pg_cache_gb() -> float:
    """Size of the leaked postgres-cluster dir (the 69G disk-full culprit)."""
    pg = Path.home() / ".cache/jac/pg"
    if not pg.exists():
        return 0.0
    return sum(f.stat().st_size for f in pg.rglob("*") if f.is_file()) / 1e9


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=50, help="max source records scanned")
    ap.add_argument("--offset", type=int, default=20000)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--k", type=int, default=3,
                    help="sequential over-generation attempts for gate-qualified records")
    ap.add_argument("--chunk", type=int, default=200,
                    help="records per bounded batch; cleanup runs between chunks")
    ap.add_argument("--min-free-gb", type=float, default=25.0)
    ap.add_argument("--gate", type=float, default=_MUTATION_GATE,
                    help="min mutation score for the hidden-test oracle (0 disables)")
    ap.add_argument("--out", default="data/step4/oxalpha_free_gen.jsonl")
    ap.add_argument("--no-synth-oracle", action="store_true",
                    help="disable test-suite synthesis for weak/thin oracles")
    ap.add_argument("--pg-cap-gb", type=float, default=8.0,
                    help="run idle-cluster wiper when ~/.cache/jac/pg exceeds this")
    args = ap.parse_args()

    out_path = REPO / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)
    done = set()
    if out_path.exists():
        for ln in out_path.read_text().splitlines():
            if ln.strip():
                done.add(json.loads(ln)["id"])
        print(f"resuming: {len(done)} rids already in {out_path}", flush=True)

    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")

    stats = {"kept": 0, "py2jac_fail": 0, "floor_test_fail": 0,
             "py2jac_timeout": 0, "floor_test_timeout": 0,
             "no_response": 0, "renamed": 0, "guard_fail": 0,
             "weak_oracle": 0, "implicit_return": 0}
    scanned = 0
    batch = []

    def flush():
        if not batch:
            return
        with open(out_path, "a") as f:
            for row in batch:
                f.write(json.dumps(row) + "\n")
        batch.clear()

    records = []
    for i in range(args.offset, min(args.offset + args.limit, len(ds))):
        r = ds[i]
        if (r.get("coverage") or 0) < 90 or r["id"] in done:
            continue
        records.append(r)

    t_start = time.perf_counter()
    for ci in range(0, len(records), args.chunk):
        chunk = records[ci:ci + args.chunk]
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = [ex.submit(process, r, args.gate, args.k,
                              not args.no_synth_oracle) for r in chunk]
            for fut in as_completed(futs):
                res = fut.result()
                scanned += 1
                stats[res["status"]] += 1
                if res["status"] == "kept":
                    batch.append(res["row"])
                total = sum(v for v in stats.values())
                extra = f" mut={res['mutation_score']}" if "mutation_score" in res else ""
                print(f"[{total}] rid={res['rid']} {res['status']}{extra} "
                      f"kept={stats['kept']}/{total}", flush=True)
                if len(batch) >= 10:
                    flush()
                # Mid-chunk PG guard: the wiper drops only IDLE clusters, so it
                # is safe while workers run. Without this, one chunk at
                # workers=6 can leak ~18GB before the between-chunk wipe.
                if total % 5 == 0 and pg_cache_gb() > args.pg_cap_gb:
                    subprocess.run([str(REPO / "scripts/ops/pg_cache_wiper.sh")],
                                   check=False)
            flush()
        # Safeguard 4: bounded batches; ALWAYS take PG offline + wipe between
        # chunks — the mutation gate leaks up to ~40 x 9MB DBs per record, no
        # periodic wiper can keep pace (2026-08-21: two disk-full incidents).
        status = cleanup_between_chunks(args.min_free_gb, force=True)
        print(f"--- chunk done ({scanned}/{len(records)} scanned, "
              f"{stats['kept']} kept); cleanup: {status}; "
              f"free={disk_free_gb():.0f}GB", flush=True)
        if disk_free_gb() < args.min_free_gb:
            print(f"ABORT: below {args.min_free_gb}GB free even after "
                  "forced wipe.", flush=True)
            break
    flush()
    wall = time.perf_counter() - t_start
    print(f"done in {wall:.0f}s: {json.dumps(stats)}", flush=True)


if __name__ == "__main__":
    main()
