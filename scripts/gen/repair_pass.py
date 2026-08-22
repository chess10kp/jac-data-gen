#!/usr/bin/env python3
"""REPAIR-PASS prototype (no-floor pipeline).

Goal: rescue virgin MultiPL-T records whose py2jac floor FAILS jac check/test
(the E1055 __add__-overload / E5092 Any-type native-lowering failures that block
the 15k push). Instead of dropping them at prep, send Python + the failing Jac
floor + the compiler error to the model and ask it to REPAIR the Jac so it
compiles (ideally natively) and preserves behavior. Guard = jac check + jac test
against the record's hidden tests.

Stages (all resumable, artifacts under --out-dir):
  1. collect : pull N virgin records; py2jac; run `jac check` on the floor to
               capture the compile error (the repair hint). Save work JSONs.
  2. pack    : batches of 10 -> repair_prompt batches.
  3. compose : cursor-agent (composer-2.5) repair calls -> candidates.jsonl
  4. guard   : jac check + jac test each candidate -> repaired.jsonl (passers)

Usage:
  python3 scripts/repair_pass.py collect --out-dir data/chunks/repair_proto --offset 400 --limit 30
  python3 scripts/repair_pass.py compose --out-dir data/chunks/repair_proto
  python3 scripts/repair_pass.py guard   --out-dir data/chunks/repair_proto
"""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "lib"))
import step4_full_loop as S  # noqa: E402

JAC = os.environ.get("JAC_BIN", "jac")   # allow testing against a custom binary

# ids already banked in the master dataset — collect must skip these to avoid
# wasted compose/guard on records that can never add a new master row.
MASTER_IDS: set[str] = set()
_MP = Path("data/composer_dataset.jsonl")
if _MP.exists():
    for _ln in _MP.read_text().splitlines():
        if _ln.strip():
            try: MASTER_IDS.add(json.loads(_ln)["id"])
            except Exception: pass


def _run(cmd: list[str], cwd: str | None = None, to: int = 90) -> tuple[int, str, str]:
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=to)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return 124, "", "TIMEOUT"


# --------------------------------------------------------------------------- #
# stage 1: collect virgin records + failing floors + compile errors
# --------------------------------------------------------------------------- #
def stage_collect(a) -> int:
    out = Path(a.out_dir); (out / "work").mkdir(parents=True, exist_ok=True)
    from datasets import load_dataset
    ds = load_dataset(S.DATASET, split="train")
    todo, seen = [], 0
    for rec in ds:
        cov = rec.get("coverage")
        if cov is None or cov < a.min_coverage: continue
        seen += 1
        if seen <= a.offset: continue
        if len(todo) >= a.limit: break
        # only records NOT already prepped anywhere (check master + this workdir)
        if (out / "work" / f"{rec['id']}.json").exists(): continue
        if rec["id"] in MASTER_IDS: continue
        todo.append(rec)
    print(f"[collect] {len(todo)} virgin records from offset {a.offset}", flush=True)

    def one(rec: dict) -> dict:
        rid = rec["id"]
        r = {"id": rid, "entrypoint": rec["entrypoint"], "stage": None}
        py_src = S.normalize_python(rec["content"].rstrip() + "\n\n"
                                    + "\n".join(rec["tests"]) + "\n")
        with tempfile.TemporaryDirectory(prefix=f"rp_{rid}_") as t:
            td = Path(t)
            (td / f"{rid}.py").write_text(py_src)
            rc, o, e = _run([JAC, "tool", "py2jac", str(td / f"{rid}.py")])
            if rc != 0:
                r["stage"] = "py2jac_fail"; r["error"] = (e or o)[-200:]; return r
            floor = o
            # compile-error hint: jac check on the floor (fast; no tests)
            chk = td / f"{rid}.jac"; chk.write_text(floor)
            rc_c, o_c, e_c = _run([JAC, "check", str(chk)], to=60)
            r["check_err"] = "" if rc_c == 0 else (e_c or o_c)[-600:]
            r["stage"] = "collected"
            r["python"] = rec["content"]
            fn = S.split_floor_fn(floor)
            r["floor_fn"] = fn
            # NOTE: slice the TRANSFORMED text by len(floor_fn), not the original
            # floor by len(floor) — with-entry blocks can sit mid-file and change
            # lengths (stray `}` bug seen on multi-block floors like 151002).
            r["test_blocks"] = S.with_entry_to_tests(floor)[len(fn):].strip()
        return r

    tallies: dict[str, int] = {}
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=a.workers) as ex:
        for i, fut in enumerate(as_completed([ex.submit(one, x) for x in todo]), 1):
            res = fut.result()
            tallies[res["stage"]] = tallies.get(res["stage"], 0) + 1
            if res["stage"] == "collected":
                (out / "work" / f"{res['id']}.json").write_text(json.dumps(res))
            if i % 20 == 0:
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s {tallies}", flush=True)
    print(f"[collect] done {time.perf_counter()-t0:.0f}s: {tallies}", flush=True)
    return 0


# --------------------------------------------------------------------------- #
# stage 2+3: pack batches + model repair calls (reuses cursor harness pattern)
# --------------------------------------------------------------------------- #
SYS_REPAIR = (
    "You are a Jac (Jaseci Labs) compiler-repair engineer. You receive Python "
    "code, its mechanical py2jac translation that FAILS to compile, and the "
    "compiler error. Rewrite the Jac so it (a) compiles natively, (b) preserves "
    "the Python behavior EXACTLY (hidden tests validate it), (c) uses concrete "
    "types (never Any/any/object) where inferable. Prefer minimal edits over "
    "rewrites: fix the constructs the error names (add type annotations, "
    "disambiguate overloaded operators, replace unsupported ops with supported "
    "equivalents). Jac syntax is mandatory: braces + semicolons, True/False/None. "
    "Output EXACTLY one ```jac fenced block per record, marked ===ID <id>===, "
    "no test blocks, no prose."
)

def _build_batch_prompt(recs: list[dict]) -> str:
    parts = ["Repair EACH failing Jac function below. Output EXACTLY this per record:\n"
             "===ID <id>===\n```jac\n<repaired jac>\n```\n"
             "Keep each entrypoint name EXACTLY. Output nothing else.\n"]
    for r in recs:
        parts.append(f"\n===ID {r['id']}===  (entrypoint: {r['entrypoint']})\n"
                     f"PYTHON:\n{r['python'][:900]}\n\n"
                     f"FAILING JAC:\n{r['floor_fn'][:1500]}\n\n"
                     f"COMPILER ERROR:\n{r.get('check_err','(none)')[:600]}\n")
    return "".join(parts)


def stage_compose(a) -> int:
    from cursor_composer_batch import call_agent  # reuse the proven harness
    out = Path(a.out_dir)
    work = sorted((out / "work").glob("*.json"))
    # pack batches of 10
    batches = out / "batches"; batches.mkdir(exist_ok=True)
    B = 10
    for i in range(0, len(work), B):
        recs = [{k: json.loads(f.read_text())[k]
                 for k in ("id", "entrypoint", "python", "floor_fn", "check_err")}
                for f in work[i:i+B]]
        (batches / f"batch{i//B:03d}.json").write_text(json.dumps(recs))
    bl = sorted(batches.glob("batch*.json"))
    cand_path = out / "candidates.jsonl"
    done_ids = set()
    if cand_path.exists():
        for ln in cand_path.read_text().splitlines():
            if ln.strip(): done_ids.add(json.loads(ln)["id"])
    print(f"[compose] {len(bl)} batches, {len(done_ids)} candidates already done", flush=True)

    def do_batch(bf: Path) -> int:
        recs = json.loads(bf.read_text())
        if all(r["id"] in done_ids for r in recs): return 0
        got = call_agent(str(bf), a.model, SYS_REPAIR, a.timeout)
        n = 0
        with open(cand_path, "a") as f:
            for rid, code in got.items():
                f.write(json.dumps({"id": rid, "candidate": code}) + "\n"); n += 1
        return n

    total = 0; t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=a.workers) as ex:
        for i, fut in enumerate(as_completed([ex.submit(do_batch, b) for b in bl]), 1):
            n = fut.result(); total += n
            print(f"  [batch {i}/{len(bl)}] +{n} cands, "
                  f"{time.perf_counter()-t0:.0f}s", flush=True)
    print(f"[compose] done: {total} candidates", flush=True)
    return 0


# --------------------------------------------------------------------------- #
# stage 4: guard — jac check + jac test each candidate
# --------------------------------------------------------------------------- #
def stage_guard(a) -> int:
    out = Path(a.out_dir)
    cands = {}
    skipped = 0
    for ln in (out / "candidates.jsonl").read_text().splitlines():
        if ln.strip():
            try:
                d = json.loads(ln); cands[d["id"]] = d["candidate"]
            except (json.JSONDecodeError, KeyError):
                skipped += 1   # tolerate power-loss-corrupt lines (NUL-filled tail)
    works = {}
    for f in (out / "work").glob("*.json"):
        try:
            d = json.loads(f.read_text()); works[d["id"]] = d
        except (json.JSONDecodeError, KeyError):
            skipped += 1
    if skipped:
        print(f"[guard] WARNING: skipped {skipped} corrupt line/file(s)", flush=True)
    print(f"[guard] {len(cands)} candidates / {len(works)} works", flush=True)

    res_path = out / "repaired.jsonl"
    done = set()
    if res_path.exists():
        for ln in res_path.read_text().splitlines():
            if ln.strip():
                try:
                    done.add(json.loads(ln)["id"])
                except (json.JSONDecodeError, KeyError):
                    pass   # tolerate power-loss-corrupt lines

    def one(w: dict, shared: str) -> dict | None:
        rid = w["id"]; cand = cands.get(rid)
        if cand is None: return None
        # shared TMPDIR -> ONE postgres for the whole guard run (no orphans)
        env = {**os.environ, "TMPDIR": shared}
        td = Path(tempfile.mkdtemp(prefix=f"rg_{rid}_", dir=shared))
        try:
            chk = td / f"{rid}.jac"; chk.write_text(cand.rstrip() + "\n")
            rc_c, o_c, e_c = _run([JAC, "check", str(chk)], to=60)
            if rc_c != 0:
                return {"id": rid, "outcome": "check_fail", "err": (e_c or o_c)[-200:]}
            g = td / f"{rid}_t.jac"
            g.write_text(cand.rstrip() + "\n\n" + w["test_blocks"] + "\n")
            rc_t, o_t, e_t = _run([JAC, "test", str(g)], to=a.test_timeout)
            if rc_t == 0:
                return {"id": rid, "outcome": "repaired", "jac": cand,
                        "python": w["python"], "entrypoint": w["entrypoint"]}
            return {"id": rid, "outcome": "test_fail", "err": (e_t or o_t)[-200:]}
        finally:
            import shutil; shutil.rmtree(td, ignore_errors=True)

    tallies: dict[str, int] = {}; added = 0; t0 = time.perf_counter()
    shared = tempfile.mkdtemp(prefix="rguard_shared_")
    with open(res_path, "a") as f, ThreadPoolExecutor(max_workers=a.workers) as ex:
        futs = {ex.submit(one, w, shared): w["id"] for w in works.values() if w["id"] not in done}
        for i, fut in enumerate(as_completed(futs), 1):
            r = fut.result()
            if r is None: continue
            tallies[r["outcome"]] = tallies.get(r["outcome"], 0) + 1
            f.write(json.dumps(r) + "\n"); added += 1
            if i % 10 == 0:
                print(f"  [{i}] {time.perf_counter()-t0:.0f}s {tallies}", flush=True)
    print(f"[guard] done: {tallies} ({added} results)", flush=True)
    import shutil; shutil.rmtree(shared, ignore_errors=True)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["collect", "compose", "guard"])
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--offset", type=int, default=400)
    ap.add_argument("--limit", type=int, default=30)
    ap.add_argument("--min-coverage", type=int, default=90)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--model", default="composer-2.5")
    ap.add_argument("--timeout", type=int, default=360)
    ap.add_argument("--test-timeout", type=int, default=120)
    a = ap.parse_args()
    return {"collect": stage_collect, "compose": stage_compose,
            "guard": stage_guard}[a.stage](a)


if __name__ == "__main__":
    sys.exit(main())
