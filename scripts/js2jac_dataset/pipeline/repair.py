#!/usr/bin/env python3
"""Model-assisted repair pass for js2jac chunks (analog of scripts/gen/repair_pass.py).

py2jac lesson: a candidate that fails `jac check` should not be silently
dropped — send the BROKEN Jac + the COMPILER ERROR (+ original JS / floor for
intent) back to the model and ask for a repair. Rescued records are guarded the
same as first-pass output; unrepaired ones still yield DPO preference pairs
(chosen = compiling floor, rejected = broken rewrite) so nothing is wasted.

Stages (all resumable; artifacts under --run-dir):
  1. collect : diff candidates.jsonl against dataset.jsonl -> ids the guard
               dropped; run `jac check` per drop to capture the error hint;
               emit work/<rid>.json + dpo_pairs.jsonl (floor-vs-broken).
  2. pack    : batches of N repair items.
  3. compose : cursor-agent via scripts/lib/composer_harness.run_composer
               (durable ledger, transient retry, fsync'd candidates).
  4. guard   : jac check each repaired candidate -> append survivors to
               dataset.jsonl + master (deduped) + extend dpo_pairs.

Usage (usually driven by js2jac_chunk.sh step 6; disable with JS2JAC_REPAIR=0):
  python3 pipeline/repair.py all  --run-dir runs/js2jac_400 --master js2jac_dataset.jsonl
  python3 pipeline/repair.py compose --run-dir runs/js2jac_400 ...
"""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from composer_harness import run_composer, add_common_args  # noqa: E402
from guard_lib import DEFAULT_JAC_REPO, jac_argv, jac_env  # noqa: E402
AS_CAP = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30
PACK_SIZE = 10

_BLOCK = re.compile(r"===ID\s+(.+?)===\s*(.*?)(?=(?:===ID\s+)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)

REPAIR_SYS = """You are an expert Jac engineer repairing code that FAILED to compile.
You get: the original TS/React SOURCE, the optional FLOOR Jac (known-good
baseline), your BROKEN Jac, and the `jac check` COMPILER ERROR.

Fix the broken Jac so it compiles AND preserves the source's behavior. Output
EXACTLY, per record:
===ID <id>===
```jac
<repaired jac>
```
or, if the construct genuinely cannot be modeled in Jac:
===ID <id>===
REJECT

HARD RULES:
1. VALID JAC ONLY — braces { } and semicolons ;, never Python colon-indent.
2. Address the compiler error FIRST; do not reorder unrelated code.
3. Keep exported component/function names EXACTLY.
4. NEVER emit `any`; infer concrete types.
5. No prose outside the ===ID blocks."""


def _run(cmd: list[str], cwd: str | None = None, to: int = 90,
         env: dict[str, str] | None = None) -> tuple[int, str]:
    """prlimit-capped subprocess (same OOM guard as js2jac_chunk.sh guard)."""
    try:
        r = subprocess.run(["prlimit", f"--as={AS_CAP}", "--"] + cmd,
                           capture_output=True, text=True, cwd=cwd, timeout=to,
                           env=env)
        return r.returncode, (r.stdout + r.stderr)
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT"


class Checker:
    def __init__(self, jac_repo: str):
        self.jac_repo, self.cache = jac_repo, {}

    def check(self, code: str | None) -> tuple[bool, str]:
        """(compiles, error_text). Cached per exact code."""
        if not code or code == "REJECT":
            return False, ""
        if code not in self.cache:
            with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as tf:
                tf.write(code)
                tp = tf.name
            try:
                rc, out = _run(
                    jac_argv("check", tp), cwd=self.jac_repo, env={**os.environ, **jac_env()}
                )
                # Run the checkout's source jac explicitly. The ambient binary
                # is incompatible with this pinned js2jac checkout.
                self.cache[code] = (rc == 0, out[-800:] if rc else "")
            finally:
                os.unlink(tp)
        return self.cache[code]


def _jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(l) for l in path.read_text().splitlines() if l.strip()]


# ---- stage 1: collect ------------------------------------------------------ #
def stage_collect(a) -> int:
    run = Path(a.run_dir)
    work = run / "repair_work"
    work.mkdir(parents=True, exist_ok=True)
    meta = {}
    for f in (run / "work").glob("*.json"):
        if f.name != "report.json":
            r = json.loads(f.read_text())
            meta[r["id"]] = r
    banked = {r["id"] for r in _jsonl(run / "dataset.jsonl")}
    master_ids = {r["id"] for r in _jsonl(Path(a.master))}
    ck = Checker(a.jac_repo)

    n_drops = n_items = n_pairs = 0
    pairs_f = open(run / "dpo_pairs.jsonl", "a")
    seen_ids = {r["id"] for r in _jsonl(work.parent / "repair_candidates.jsonl")}
    for c in _jsonl(run / "candidates.jsonl"):
        rid, code = c["id"], c.get("candidate")
        if (rid in banked or rid in master_ids or rid in seen_ids
                or not code or code == "REJECT" or rid not in meta):
            continue
        n_drops += 1
        ok, err = ck.check(code)
        if ok:
            continue  # compiles but wasn't banked (ORM gate reject etc.) — leave it
        m = meta[rid]
        floor = m.get("floor_jac")
        floor_ok, _ = ck.check(floor)
        if floor_ok:
            # DPO pair: chosen = known-compiling floor, rejected = broken rewrite
            pairs_f.write(json.dumps({"id": rid, "chosen": floor,
                                      "rejected": code, "why": "check-fail"}) + "\n")
            n_pairs += 1
        (work / f"{_safe(rid)}.json").write_text(json.dumps({
            "id": rid, "source_js": (m.get("source_js") or "")[:3500],
            "floor_jac": floor or "", "broken_jac": code[:3500],
            "check_err": err[-600:],
        }))
        n_items += 1
    pairs_f.close()
    print(f"[collect] {n_drops} drops examined -> {n_items} repair items, "
          f"{n_pairs} DPO pairs (floor-vs-broken)", flush=True)
    return 0


def _safe(rid: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]", "_", rid)[-120:]


# ---- stage 2: pack --------------------------------------------------------- #
def stage_pack(a) -> int:
    run = Path(a.run_dir)
    batches = run / "repair_batches"
    batches.mkdir(exist_ok=True)
    items = sorted((run / "repair_work").glob("*.json"))
    nb = 0
    for i in range(0, len(items), PACK_SIZE):
        recs = [json.loads(f.read_text()) for f in items[i:i + PACK_SIZE]]
        (batches / f"rb{i // PACK_SIZE:03d}.json").write_text(json.dumps(recs))
        nb += 1
    print(f"[pack] {len(items)} items -> {nb} batches", flush=True)
    return 0


# ---- stage 3: compose (via shared harness) --------------------------------- #
def build_prompt(recs: list[dict]) -> str:
    parts = [f"{REPAIR_SYS}\n\nRepair EACH record below.\n"]
    for r in recs:
        parts.append(f"\n===ID {r['id']}===\nSOURCE:\n{r['source_js']}\n")
        if r.get("floor_jac"):
            parts.append(f"FLOOR (known-good baseline for intent):\n{r['floor_jac'][:2000]}\n")
        parts.append(f"BROKEN JAC:\n{r['broken_jac']}\n"
                     f"COMPILER ERROR:\n{r['check_err']}\n")
    return "".join(parts)


def parse_result(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in _BLOCK.finditer(text or ""):
        seg = m.group(2)
        if re.match(r"^\s*REJECT\b", seg, re.I):
            out[m.group(1).strip()] = "REJECT"
            continue
        fm = _FENCE.search(seg)
        if fm:
            out[m.group(1).strip()] = fm.group(1).strip()
    return out


# ---- stage 4: guard + append ----------------------------------------------- #
def stage_guard(a) -> int:
    run = Path(a.run_dir)
    cand = run / "repair_candidates.jsonl"
    ds = run / "dataset.jsonl"
    master = Path(a.master)
    ck = Checker(a.jac_repo)
    rows = _jsonl(cand)
    ds_ids = {r["id"] for r in _jsonl(ds)}
    master_ids = {r["id"] for r in _jsonl(master)}
    meta = {}
    for f in (run / "work").glob("*.json"):
        if f.name != "report.json":
            r = json.loads(f.read_text())
            meta[r["id"]] = r
    repaired_map: dict[str, str] = {}
    appended = 0
    with open(ds, "a") as out, open(master, "a") as mf:
        for c in rows:
            rid, code = c["id"], c.get("candidate")
            if rid in ds_ids or rid in master_ids or not code or code == "REJECT":
                continue
            ok, _ = ck.check(code)
            if not ok:
                continue
            m = meta.get(rid, {})
            row = {"id": rid, "repo": m.get("repo"), "path": m.get("path"),
                   "commit": m.get("commit"), "spdx": m.get("spdx"),
                   "status_in": m.get("status"), "source": "js2jac_repair",
                   "js": m.get("source_js"), "jac": code}
            out.write(json.dumps(row) + "\n")
            ds_ids.add(rid)
            mf.write(json.dumps({**row, "chunk": a.tag}) + "\n")
            master_ids.add(rid)
            repaired_map[rid] = code
            appended += 1
    # DPO pairs for rescues: chosen = repaired Jac (compiles), rejected = broken
    paired = 0
    with open(run / "dpo_pairs.jsonl", "a") as pairs_f:
        for f in sorted((run / "repair_work").glob("*.json")):
            w = json.loads(f.read_text())
            if w["id"] in repaired_map:
                pairs_f.write(json.dumps({"id": w["id"],
                                          "chosen": repaired_map[w["id"]],
                                          "rejected": w["broken_jac"],
                                          "why": "repair-rescued"}) + "\n")
                paired += 1
    print(f"[guard] repaired+appended {appended} to {master.name}; "
          f"{paired} rescue DPO pairs", flush=True)
    return 0


# ---- driver ---------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="stage", required=True)
    for name in ("collect", "pack", "compose", "guard", "all"):
        s = sub.add_parser(name)
        s.add_argument("--run-dir", required=True)
        s.add_argument("--master", default="js2jac_dataset.jsonl")
        s.add_argument("--jac-repo", default=os.environ.get("JAC_REPO", DEFAULT_JAC_REPO))
        s.add_argument("--tag", default="")
        add_common_args(s)
        s.set_defaults(stage=name)
    a = ap.parse_args()

    if a.stage in ("compose", "all"):
        # run_composer drives --batch-dir -> --out; point it at the repair dirs
        a.batch_dir = str(Path(a.run_dir) / "repair_batches")
        a.out = str(Path(a.run_dir) / "repair_candidates.jsonl")

    if a.stage in ("collect", "all"):
        rc = stage_collect(a)
        if a.stage != "all":
            return rc
    if a.stage in ("pack", "all"):
        stage_pack(a)
    if a.stage in ("compose", "all"):
        rc = run_composer("js2jac-repair", a, build_prompt, parse_result)
        if a.stage != "all":
            return rc
    if a.stage in ("guard", "all"):
        return stage_guard(a)
    return 0


if __name__ == "__main__":
    sys.exit(main())
