#!/usr/bin/env python3
"""Pack OSP repair traces into a v1 dataset (natural pairs + trajectories + Tier-A pool).

Harvests gate-verified repair structure from the existing OSP failure ledgers:

  split=code_fix     broken attempt (code+error)  -> gate+test-verified passing version
                     Sources: minimax/composer/glm/gpt/luna/muse failure ledgers
                     intersected with data/osp_dataset_pass.jsonl (exact id match).
  split=test_fix     broken testgen attempt       -> test-verified passing tests
                     Sources: osp_testgen_failures.jsonl x osp_test_results.jsonl (verdict=PASS).
  split=trajectory   full multi-attempt minimax repair sequences for ids that
                     eventually passed (harvested agentic loop traces).
  split=broken_pool  broken code + real compiler error, no known fix yet —
                     the gate-in-the-loop (Tier A) generation feed.

Emits data/osp_repair/{split}.jsonl + README. Stdlib only.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATA = REPO / "data"
OUT = DATA / "osp_repair"

FAIL_LEDGERS = {
    "minimax": "osp_minimax_failures.jsonl",
    "composer": "osp_composer_failures.jsonl",
    "glm": "osp_glm_failures.jsonl",
    "gpt": "osp_gpt_failures.jsonl",
    "luna": "osp_luna_failures.jsonl",
    "muse": "osp_muse_failures.jsonl",
}
EPOCH = datetime(2026, 1, 1, tzinfo=timezone.utc).timestamp()


def iter_jsonl(path: Path):
    with path.open() as f:
        for line in f:
            if line.strip():
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue


def error_code(err: str | None) -> str | None:
    """Extract the primary jac error code, e.g. E1032, from an error string."""
    if not err:
        return None
    m = re.search(r"error\[([A-Z]\d+)\]", err)
    if m:
        return m.group(1)
    m = re.search(r"\b([A-Z]\d{3,4})\b", err)
    return m.group(1) if m else None


def strip_fence(text: str) -> str:
    m = re.search(r"```(?:jac|jacl|python)?\s*\n(.*?)```", text, re.S)
    return (m.group(1) if m else text).strip() + "\n"


def ts_key(r: dict) -> float:
    ts = r.get("ts")
    if isinstance(ts, str):
        try:
            return datetime.fromisoformat(ts).timestamp()
        except ValueError:
            return 0.0
    return float(ts or 0.0)


def base_id(i: str) -> str:
    return i  # ids carry generator suffixes; exact-id matching is the pairing key


def load_pass_records() -> dict[str, dict]:
    """Latest verified pass record per exact id."""
    best: dict[str, dict] = {}
    for r in iter_jsonl(DATA / "osp_dataset_pass.jsonl"):
        cur = best.get(r["id"])
        if cur is None or ts_key(r) > ts_key(cur):
            best[r["id"]] = r
    return best


def pass_code(rec: dict) -> str:
    msgs = rec.get("messages") or []
    for m in reversed(msgs):
        if m.get("role") == "assistant":
            return strip_fence(m.get("content", ""))
    return ""


def pass_prompt(rec: dict) -> str:
    for m in rec.get("messages") or []:
        if m.get("role") == "user":
            return m.get("content", "")
    return ""


def load_test_pass() -> dict[str, dict]:
    """Latest PASS test result per exact id."""
    best: dict[str, dict] = {}
    for r in iter_jsonl(DATA / "osp_test_results.jsonl"):
        if r.get("verdict") != "PASS":
            continue
        cur = best.get(r["id"])
        if cur is None or ts_key(r) > ts_key(cur):
            best[r["id"]] = r
    return best


def earliest_with_code(rows: list[dict]) -> dict | None:
    """Earliest attempt that actually carries code (parse_error rows may not)."""
    with_code = [r for r in rows if r.get("code")]
    pool = with_code or rows
    return min(pool, key=lambda r: (r.get("attempt", 0), ts_key(r))) if pool else None


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    stats: Counter = Counter()

    passrecs = load_pass_records()
    testpass = load_test_pass()
    print(f"pass records (latest per id): {len(passrecs)} | test PASS ids: {len(testpass)}")

    # ---- load failure ledgers -------------------------------------------------
    ledger: dict[str, list[dict]] = defaultdict(list)
    per_gen_ids: dict[str, set[str]] = defaultdict(set)
    for gen, fname in FAIL_LEDGERS.items():
        path = DATA / fname
        n = 0
        if path.exists():
            for r in iter_jsonl(path):
                r = dict(r, generator=gen)
                ledger[r["id"]].append(r)
                per_gen_ids[gen].add(r["id"])
                n += 1
        print(f"  {gen}: {n} failure rows, {len(per_gen_ids[gen])} ids")

    # ---- split 1: natural code-fix pairs --------------------------------------
    code_pairs = []
    seen_pair: set[str] = set()
    for fid, rows in ledger.items():
        if fid not in passrecs:
            continue
        broken = earliest_with_code(rows)
        if broken is None:
            continue
        fixed = passrecs[fid]
        pair_id = f"codefix__{fid}"
        if pair_id in seen_pair:
            continue
        seen_pair.add(pair_id)
        code_pairs.append({
            "id": pair_id,
            "split": "code_fix",
            "target_id": fid,
            "source": "natural",
            "verification": "jac_check_gate+jac_test_pass",
            "prompt": pass_prompt(fixed),
            "broken": {
                "generator": broken["generator"],
                "attempt": broken.get("attempt"),
                "stage": broken.get("stage"),
                "error": broken.get("error"),
                "error_code": error_code(broken.get("error")),
                "code": broken.get("code"),
                "ts": broken.get("ts"),
            },
            "fixed": {
                "generator": fixed.get("generator"),
                "generator_model_id": fixed.get("generator_model_id"),
                "code": pass_code(fixed),
                "jac_tests": fixed.get("jac_tests"),
                "test_verdict": fixed.get("test_verdict"),
                "test_detail": fixed.get("test_detail"),
                "gate_class": fixed.get("gate_class"),
                "ts": fixed.get("generation_date"),
            },
        })
    stats["code_fix"] = len(code_pairs)

    # ---- split 2: natural test-fix pairs --------------------------------------
    tg_rows: dict[str, list[dict]] = defaultdict(list)
    for r in iter_jsonl(DATA / "osp_testgen_failures.jsonl"):
        tg_rows[r["id"]].append(r)
    test_pairs = []
    for tid, rows in tg_rows.items():
        ok = testpass.get(tid)
        if ok is None:
            continue
        broken = min(rows, key=lambda r: ts_key(r))
        fixed = passrecs.get(tid, {})
        test_pairs.append({
            "id": f"testfix__{tid}",
            "split": "test_fix",
            "target_id": tid,
            "source": "natural",
            "verification": "jac_test_pass",
            "broken_tests": {
                "stage": broken.get("stage"),
                "error": broken.get("error"),
                "tests": broken.get("tests"),
                "ts": broken.get("ts"),
            },
            "fixed_tests": {
                "tests": ok.get("tests"),
                "detail": ok.get("detail"),
                "run_tag": ok.get("run_tag"),
                "ts": ok.get("ts"),
            },
            "program_code": (fixed.get("jac_tests") and pass_code(fixed)) or None,
        })
    stats["test_fix"] = len(test_pairs)

    # ---- split 3: multi-attempt minimax trajectories ---------------------------
    mm_ids = per_gen_ids.get("minimax", set())
    trajectories = []
    for fid in sorted(mm_ids):
        if fid not in passrecs:
            continue
        rows = sorted(ledger[fid], key=lambda r: (r.get("attempt", 0), ts_key(r)))
        fixed = passrecs[fid]
        trajectories.append({
            "id": f"traj__{fid}",
            "split": "trajectory",
            "target_id": fid,
            "source": "natural_harvest",
            "prompt": pass_prompt(fixed),
            "n_attempts": len(rows),
            "steps": [{
                "attempt": r.get("attempt"),
                "stage": r.get("stage"),
                "status": "fail",
                "error": r.get("error"),
                "error_code": error_code(r.get("error")),
                "code": r.get("code"),
                "ts": r.get("ts"),
            } for r in rows],
            "final": {
                "generator": fixed.get("generator"),
                "code": pass_code(fixed),
                "jac_tests": fixed.get("jac_tests"),
                "test_verdict": fixed.get("test_verdict"),
                "status": "pass",
            },
        })
    stats["trajectory"] = len(trajectories)

    # ---- split 4: broken pool (Tier A feed) ------------------------------------
    any_pass = set(passrecs)  # ids with a known verified fix
    pool = []
    fault_hist: Counter = Counter()
    for fid, rows in ledger.items():
        if fid in any_pass:
            continue
        broken = earliest_with_code(rows)
        if broken is None or not broken.get("code"):
            continue
        pool.append({
            "id": f"broken__{fid}",
            "split": "broken_pool",
            "target_id": fid,
            "generator": broken["generator"],
            "n_attempts": len(rows),
            "error": broken.get("error"),
            "error_code": error_code(broken.get("error")),
            "code": broken.get("code"),
            "ts": broken.get("ts"),
            "fault_class": "unlabeled",
        })
        fault_hist[error_code(broken.get("error")) or "unparsed"] += 1
    stats["broken_pool"] = len(pool)

    # ---- write ------------------------------------------------------------------
    def dump(name: str, rows: list[dict]) -> Path:
        p = OUT / name
        with p.open("w") as f:
            for r in rows:
                f.write(json.dumps(r) + "\n")
        print(f"wrote {len(rows):5d} rows  {p.relative_to(REPO)}  ({p.stat().st_size/1e6:.1f} MB)")
        return p

    dump("code_fix.jsonl", code_pairs)
    dump("test_fix.jsonl", test_pairs)
    dump("trajectory.jsonl", trajectories)
    dump("broken_pool.jsonl", pool)

    print("\nsummary:", dict(stats))
    print("\nbroken_pool top error codes:")
    for code, n in fault_hist.most_common(12):
        print(f"  {code:10s} {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
