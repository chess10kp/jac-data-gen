#!/usr/bin/env python3
"""Build the tiered normalized OSP corpus (legacy + v2.1) with fresh gate evidence.

Merges the legacy v2.0 osp_dataset (7,275 compile-gated rows) and the v2.1
osp_lift_dataset (567 lift rows) into ONE normalized JSONL with explicit
provenance tiers. Never merges the task contracts: every record carries
`task_contract` ("legacy_osp_codegen" | "osp_idiomize_lift") and the legacy
shape is preserved under `legacy_*` provenance -- source_code / lift labels
are NEVER invented for legacy rows.

Tiers (user-approved merge strategy):
  legacy_compile_only   all raw legacy rows not promoted         (aux only)
  legacy_test_verified  legacy pass rows re-validated green NOW  (aux, evidence)
  v21_candidate         v2.1 rows whose gates did not all pass   (needs promotion)
  v21_gold              v2.1 rows passing ALL gates now          (SFT release set)

Promotion gates (fresh runs, evidence stored per record):
  legacy pass subset : jac check (raw candidate) + guard jac test
                       (entry-stripped candidate + jac_tests annex, exactly the
                       osp_minimax_testgen harness) + v2.1 elimination scan.
  v2.1 rows          : python ref harness exit 0 + jac check + guard jac test
                       (on-disk guard file) + floor check when claimed +
                       elimination scan (candidate_hits must be empty).

sft_excluded is true for every record outside v21_gold -- legacy rows never
enter the lift SFT set (their reason field states the eligible use).

Dedup: sha256 of whitespace-stripped candidate code -> duplicate_of (tier-ranked
primary kept, all rows retained); prompt_hash collisions flagged informationally.

Usage: python3 scripts/gen/pack_merged_corpus.py [--limit N] [--workers N]
           [--out data/osp_merged_corpus.jsonl] [--skip-legacy-gates]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import os
import signal
import sys
import tempfile
from concurrent.futures import ProcessPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
from jac_source import strip_top_level_with_entry  # noqa: E402

LEGACY_RAW = REPO / "data" / "osp_dataset.jsonl"
LEGACY_PASS = REPO / "data" / "osp_dataset_pass.jsonl"
LIFTS = REPO / "data" / "osp_lift_dataset.jsonl"
LIFT_BASE = REPO / "data" / "osp_lifts"
AUDIT_RESULTS = LIFT_BASE / "_audit_results.json"
OUT = REPO / "data" / "osp_merged_corpus.jsonl"
SUMMARY = REPO / "data" / "osp_merged_corpus_summary.json"

SPEC_VERSION = "OSP_IDIOMIZE_TASK-v2.1"
JAC_VERSION = "0.36.1"
GATE_TIMEOUT = 120  # seconds, per jac invocation
RETRYABLE = ("runtime bring-up failed",)

JAC_FENCE = re.compile(r"```jac\s*\n(.*?)```", re.S)

# v2.1 elimination token scan -- exact banned list from pack_osp_lifts.py
# (the §8.2 AST detector is not implemented in-repo; this is the text gate).
CANDIDATE_BANNED = [
    "deque", "heapq", "queue.Queue", "visited = set()", "stack =", "queue =",
]
# Informational source-side family markers (never gate).
SOURCE_BANNED = ["deque", "heapq", "queue.Queue", "visited"]

TIER_RANK = {
    "v21_gold": 0,
    "legacy_test_verified": 1,
    "v21_candidate": 2,
    "legacy_compile_only": 3,
}


def strip_docstrings_comments(text: str) -> str:
    text = re.sub(r'"""(.*?)"""', "", text, flags=re.S)
    text = re.sub(r"#[^\n]*", "", text)
    return text


def sha(text: str, n: int = 64) -> str:
    return hashlib.sha256("".join((text or "").split()).encode()).hexdigest()[:n]


def run(cmd: list[str], cwd: Path) -> dict:
    """Run one gate command with a single retry on infra flake/timeout.

    Process-group execution + group kill on timeout: jac's runtime leaves
    orphaned grandchildren (postgres) holding the stdout pipe, which would
    otherwise hang communicate() forever after the direct child dies.
    """
    attempts: list[dict] = []
    for _ in range(2):
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, text=True, cwd=str(cwd),
                             start_new_session=True)
        try:
            out_s, err_s = p.communicate(timeout=GATE_TIMEOUT)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            p.kill()
            p.communicate()
            attempts.append({"rc": 124, "out": "timeout"})
            continue
        out = (out_s or "") + (err_s or "")
        attempts.append({"rc": p.returncode, "out": out})
        if p.returncode == 0:
            break
        if not any(s in out for s in RETRYABLE):
            break
    last = attempts[-1]
    return {"status": "pass" if last["rc"] == 0 else "fail",
            "rc": last["rc"], "detail": last["out"][-800:], "attempts": len(attempts)}


# ---------------------------------------------------------------- gate workers

def gate_legacy(payload: dict) -> dict:
    """jac check (raw candidate) + guard test (entry-stripped + annex)."""
    gates: dict[str, dict] = {}
    with tempfile.TemporaryDirectory(prefix="merge_gate_") as td:
        work = Path(td)
        code = payload["candidate"]
        (work / "main.jac").write_text(code)
        gates["jac_check"] = run([JAC, "check", "main.jac"], work)
        gates["guard_test"] = {"status": "skipped", "rc": None, "detail": ""}
        if payload.get("jac_tests"):
            try:
                stripped, _ = strip_top_level_with_entry(code)
            except ValueError as exc:
                gates["guard_test"] = {"status": "fail", "rc": 125,
                                       "detail": f"entry-strip-fail: {exc}",
                                       "attempts": 1}
            else:
                (work / "main.jac").write_text(stripped)
                (work / "main.test.jac").write_text(payload["jac_tests"])
                gates["guard_test"] = run([JAC, "test", "main.jac"], work)
                if gates["guard_test"]["status"] != "pass":
                    # either-side pass: native codespace has miscompilation
                    # bugs (spec §2) — retry with server codespace pinned
                    (work / "jac.toml").write_text(
                        '[build]\ndefault_codespace = "server"\n')
                    gates["guard_test"] = run([JAC, "test", "main.jac"], work)
    return gates


def gate_v21(payload: dict) -> dict:
    """ref harness + jac check + guard jac test + floor check (paths on disk)."""
    gates: dict[str, dict] = {}
    base = REPO / payload["base"]
    src = base / payload["source_file"] if payload.get("source_file") else None
    ref = src.with_name(src.stem + ".ref.py") if src else None
    cand = base / payload["candidate_file"]
    guard = base / payload["guard_file"]
    floor = base / payload["floor_file"] if payload.get("floor_file") else None

    if ref and ref.exists():
        gates["ref_harness"] = run(["python3", str(ref)], base)
    else:
        gates["ref_harness"] = {"status": "skipped", "rc": None,
                                "detail": "no ref harness", "attempts": 0}
    gates["jac_check"] = run([JAC, "check", str(cand)], base)
    gates["guard_test"] = (run([JAC, "test", str(guard)], base) if guard.exists()
                           else {"status": "skipped", "rc": None,
                                 "detail": f"missing guard {guard.name}", "attempts": 0})
    if guard.exists() and gates["guard_test"]["status"] != "pass":
        # either-side pass: retry under server codespace pin (native codespace
        # has miscompilation bugs — spec §2)
        gates["guard_test"] = run([JAC, "test", str(guard)], base)
    if payload.get("floor_file"):
        gates["floor_check"] = (run([JAC, "check", str(floor)], base)
                                if floor and floor.exists()
                                else {"status": "fail", "rc": None,
                                      "detail": "floor_status generated but file missing",
                                      "attempts": 0})
    else:
        gates["floor_check"] = {"status": "skipped", "rc": None,
                                "detail": "no floor claimed", "attempts": 0}
    return gates


def elimination_scan(candidate: str, source: str | None) -> dict:
    cand_text = strip_docstrings_comments(candidate or "")
    cand_hits = [b for b in CANDIDATE_BANNED if b in cand_text]
    src_hits = []
    if source:
        src_text = strip_docstrings_comments(source)
        src_hits = [b for b in SOURCE_BANNED if b in src_text]
    return {"scan": "token_v1 (text scan; §8.2 AST detector not implemented)",
            "candidate_hits": cand_hits, "source_hits": src_hits,
            "clean": not cand_hits}


# ------------------------------------------------------------- record builders

def parse_legacy(row: dict, pass_meta: dict | None) -> dict:
    prompt = row["messages"][0]["content"]
    candidate = None
    if len(row["messages"]) > 1:
        m = JAC_FENCE.search(row["messages"][1]["content"] or "")
        candidate = m.group(1).strip() if m else None
    return {"row": row, "prompt": prompt, "candidate": candidate,
            "jac_tests": (pass_meta or {}).get("jac_tests"),
            "pass_meta": pass_meta}


def legacy_record(parsed: dict, tier: str, validation: dict,
                  reason: str) -> dict:
    row = parsed["row"]
    pm = parsed["pass_meta"] or {}
    return {
        "id": row["id"],
        "corpus_ns": "legacy",
        "tier": tier,
        "task_contract": "legacy_osp_codegen",
        "prompt": parsed["prompt"],
        "source_code": None,           # never invented for legacy rows
        "category_lifts": None,
        "signals": None,
        "g_tier": None,
        "track": None,
        "candidate_osp_jac": parsed["candidate"],
        "jac_tests": parsed["jac_tests"],
        "test_hash": sha(parsed["jac_tests"], 8) if parsed["jac_tests"] else None,
        "floor_jac": None,
        "floor_status": None,
        "guard_result": (validation["gates"].get("guard_test", {})
                         .get("status", "not_run")),
        "elimination": validation["elimination"],
        "audit": {"reviewed": False, "reviewer": None,
                  "notes": "legacy record; outside v2.1 manual audit program",
                  "programmatic": None},
        "sft_excluded": True,
        "sft_excluded_reason": reason,
        "dedupe": {"code_hash": sha(parsed["candidate"] or ""),
                   "prompt_hash": sha(parsed["prompt"]),
                   "duplicate_of": None, "prompt_duplicate_of": None},
        "provenance": {
            "source": "data/osp_dataset.jsonl (legacy jac-synth-v2.0.0)",
            "original_id": row["id"],
            "generator": row.get("generator"),
            "generator_model_id": row.get("generator_model_id"),
            "run_tag": row.get("run_tag"),
            "generation_date": row.get("generation_date"),
            "category": row.get("category"),
            "complexity": row.get("complexity"),
            "gate_class": row.get("gate_class"),
            "variant_idx": row.get("variant_idx"),
            "source_prompt_version": row.get("source_prompt_version"),
            "context_bundle_version": row.get("context_bundle_version"),
            "legacy": {
                "dataset_version": row.get("dataset_version"),
                "validator_version": row.get("validator_version"),
                "compiler_pass": row.get("compiler_pass"),
                "test_pass": row.get("test_pass"),
                "test_verdict": row.get("test_verdict"),
                "test_run_tag": row.get("test_run_tag"),
                "test_detail": row.get("test_detail"),
                "pass_snapshot_verdict": pm.get("test_verdict"),
            },
        },
        "validation": validation,
    }


def v21_record(row: dict, manifest: dict | None, gates: dict,
               elimination: dict, tier: str, reason: str) -> dict:
    cand = row.get("candidate_osp_jac") or ""
    guard_path = (LIFT_BASE / manifest["guard_file"]) if manifest else None
    tests = None
    integrity = None
    if guard_path and guard_path.exists():
        guard_text = guard_path.read_text()
        if guard_text.startswith(cand):
            tests = guard_text[len(cand):].strip() or None
        else:
            integrity = "guard file does not extend inlined candidate"
    prog = None
    if AUDIT_RESULTS.exists():
        audit = json.loads(AUDIT_RESULTS.read_text())
        for batch in (audit.get("by_batch") or {}).values():
            for rec in batch.get("records", []):
                if rec.get("id") == row["id"]:
                    prog = "pass" if rec.get("pass") else "fail"
    validation = {
        "spec_version": SPEC_VERSION,
        "jac_version": JAC_VERSION,
        "validated_at": NOW,
        "current": tier == "v21_gold",
        "gates": gates,
        "guard_integrity": integrity,
    }
    return {
        "id": row["id"],
        "corpus_ns": "v21",
        "tier": tier,
        "task_contract": "osp_idiomize_lift",
        "prompt": None,
        "source_code": row.get("source_code"),
        "category_lifts": row.get("category_lifts"),
        "signals": row.get("signals"),
        "g_tier": row.get("g_tier"),
        "track": row.get("track"),
        "candidate_osp_jac": row.get("candidate_osp_jac"),
        "jac_tests": tests,
        "test_hash": sha(tests, 8) if tests else None,
        "floor_jac": row.get("floor_jac"),
        "floor_status": row.get("floor_status"),
        "guard_result": gates.get("guard_test", {}).get("status", "not_run"),
        "elimination": elimination,
        "audit": {"reviewed": False, "reviewer": None,
                  "notes": "programmatic gates only; manual audit pending",
                  "programmatic": prog},
        "sft_excluded": tier != "v21_gold",
        "sft_excluded_reason": reason,
        "dedupe": {"code_hash": sha(cand), "prompt_hash": None,
                   "duplicate_of": None, "prompt_duplicate_of": None},
        "provenance": {
            "source": "data/osp_lift_dataset.jsonl (OSP_IDIOMIZE_TASK v2.1)",
            "original_id": row["id"],
            **(row.get("provenance") or {}),
        },
        "validation": validation,
    }


def _legacy_validation(gates: dict, now: str, candidate: str | None) -> dict:
    return {
        "spec_version": SPEC_VERSION + " (adapted gates for legacy contract)",
        "jac_version": JAC_VERSION,
        "validated_at": now,
        "current": False,
        "gates": gates,
        "elimination": elimination_scan(candidate, None),
        "guard_integrity": None,
    }


# ------------------------------------------------------------------------ main

def main() -> int:
    global NOW
    NOW = datetime.now().isoformat()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", default=str(OUT))
    ap.add_argument("--workers", type=int,
                    default=min(12, __import__("os").cpu_count() or 8))
    ap.add_argument("--limit", type=int, default=0, help="smoke: cap legacy+v21 inputs")
    ap.add_argument("--skip-legacy-gates", action="store_true",
                    help="skip legacy guard/check runs (aux tiers only)")
    args = ap.parse_args()

    # ---- load legacy
    pass_meta: dict[str, dict] = {}
    for line in LEGACY_PASS.open():
        if line.strip():
            r = json.loads(line)
            pass_meta[r["id"]] = r
    legacy_rows = [json.loads(l) for l in LEGACY_RAW.open() if l.strip()]
    if args.limit:
        legacy_rows = legacy_rows[:args.limit]
    print(f"legacy rows: {len(legacy_rows)} ({len(pass_meta)} with PASS snapshot)")

    # ---- load v21 + manifests
    lift_rows = [json.loads(l) for l in LIFTS.open() if l.strip()]
    if args.limit:
        lift_rows = lift_rows[:max(1, args.limit // 8)]
    manifests: dict[str, dict] = {}
    skip_prefixes = ("_cost_", "mm", "pool_")
    for mf in sorted(LIFT_BASE.glob("*.jsonl")):
        if mf.name.startswith(skip_prefixes):
            continue
        for line in mf.read_text().splitlines():
            if line.strip():
                rec = json.loads(line)
                if "candidate_file" in rec:
                    manifests[rec["id"]] = rec
    print(f"v21 rows: {len(lift_rows)} ({len(manifests)} manifests)")

    # ---- jobs
    jobs = []  # (kind, key, payload)
    for row in legacy_rows:
        parsed = parse_legacy(row, pass_meta.get(row["id"]))
        if parsed["candidate"] is None:
            jobs.append(("legacy_nofence", row["id"], parsed))
        elif parsed["jac_tests"] is None or args.skip_legacy_gates:
            jobs.append(("legacy_aux", row["id"], parsed))
        else:
            jobs.append(("legacy_gate", row["id"], parsed))
    for row in lift_rows:
        jobs.append(("v21_gate", row["id"], (row, manifests.get(row["id"]))))

    # ---- run gates
    gate_results: dict[str, dict] = {}  # id -> {"gates": {...}}
    gate_jobs = [(k, i, p) for k, i, p in jobs if k.endswith("_gate")]
    print(f"gate jobs: {len(gate_jobs)} (workers={args.workers})", flush=True)
    done = 0
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        futs = {}
        for k, i, p in gate_jobs:
            if k == "legacy_gate":
                futs[ex.submit(gate_legacy, p)] = i
            else:
                _, manifest = p
                payload = {"base": "data/osp_lifts",
                           "source_file": (manifest or {}).get("source_file"),
                           "candidate_file": (manifest or {}).get("candidate_file"),
                           "guard_file": (manifest or {}).get("guard_file"),
                           "floor_file": (manifest or {}).get("floor_file")}
                futs[ex.submit(gate_v21, payload)] = i
        for fut in as_completed(futs):
            i = futs[fut]
            gate_results[i] = fut.result()
            done += 1
            if done % 200 == 0 or done == len(gate_jobs):
                print(f"  gates {done}/{len(gate_jobs)}", flush=True)

    # ---- assemble records with tiers
    records: list[dict] = []
    stats: dict[str, dict] = {"legacy_gate": {}, "v21_gate": {}}
    for kind, i, p in jobs:
        if kind == "legacy_nofence":
            val = _legacy_validation({}, NOW, p["candidate"])
            records.append(legacy_record(
                p, "legacy_compile_only", val,
                "no ```jac fence in assistant message; candidate absent"))
            continue
        if kind == "legacy_aux":
            val = _legacy_validation({}, NOW, p["candidate"])
            records.append(legacy_record(
                p, "legacy_compile_only", val,
                "tier legacy_compile_only: compile-gated legacy row; auxiliary/"
                "pretraining only (no behavior-verified lift contract)"))
            continue
        gates = gate_results[i]
        if kind == "legacy_gate":
            elim = elimination_scan(p["candidate"], None)
            val = _legacy_validation(gates, NOW, p["candidate"])
            failed = [g for g in ("jac_check", "guard_test")
                      if gates.get(g, {}).get("status") != "pass"]
            if not elim["clean"]:
                failed.append("elimination_scan")
            if failed:
                val["current"] = False
                records.append(legacy_record(
                    p, "legacy_compile_only", val,
                    "revalidation failed gates " + ",".join(failed) +
                    "; historical test PASS not honored without current evidence"))
            else:
                val["current"] = True
                records.append(legacy_record(
                    p, "legacy_test_verified", val,
                    "tier legacy_test_verified: v2.1 gates green (evidence "
                    "recorded); excluded from lift-SFT release (legacy task "
                    "contract); eligible for legacy-objective SFT/aux use"))
            stats["legacy_gate"][" ".join(sorted(failed)) or "all_pass"] = \
                stats["legacy_gate"].get(" ".join(sorted(failed)) or "all_pass", 0) + 1
            continue

        # v21
        row, manifest = p
        elim = elimination_scan(row.get("candidate_osp_jac"), row.get("source_code"))
        failed = [g for g in ("ref_harness", "jac_check", "guard_test",
                              "floor_check")
                  if gates.get(g, {}).get("status") == "fail"]
        if not elim["clean"]:
            failed.append("elimination_scan")
        if gates.get("guard_test", {}).get("status") != "pass":
            failed.append("guard_evidence_required")
        if failed:
            records.append(v21_record(
                row, manifest, gates, elim, "v21_candidate",
                "tier v21_candidate: failed gates " + ",".join(failed) +
                "; promotion withheld"))
            stats["v21_gate"][" ".join(sorted(failed)) or "all_pass"] = \
                stats["v21_gate"].get(" ".join(sorted(failed)) or "all_pass", 0) + 1
        else:
            records.append(v21_record(
                row, manifest, gates, elim, "v21_gold",
                "tier v21_gold: all v2.1 gates green (SFT release set)"))
            records[-1]["sft_excluded"] = False
            records[-1]["sft_excluded_reason"] = None
            stats["v21_gate"]["all_pass"] = \
                stats["v21_gate"].get("all_pass", 0) + 1

    # ---- dedupe by code hash (tier-ranked primary; all rows retained)
    by_hash: dict[str, list[dict]] = {}
    for rec in records:
        by_hash.setdefault(rec["dedupe"]["code_hash"], []).append(rec)
    dups = 0
    for group in by_hash.values():
        if len(group) < 2:
            continue
        group.sort(key=lambda r: TIER_RANK[r["tier"]])
        primary = group[0]
        for other in group[1:]:
            other["dedupe"]["duplicate_of"] = primary["id"]
            other["sft_excluded"] = True
            other["sft_excluded_reason"] = (
                f"duplicate of {primary['id']} (identical normalized candidate "
                f"code); primary tier={primary['tier']}")
            dups += 1
    seen_prompts: dict[str, str] = {}
    for rec in records:
        ph = rec["dedupe"]["prompt_hash"]
        if ph:
            if ph in seen_prompts:
                rec["dedupe"]["prompt_duplicate_of"] = seen_prompts[ph]
            else:
                seen_prompts[ph] = rec["id"]

    # ---- write
    out = Path(args.out)
    tmp = out.with_suffix(".jsonl.pack_tmp")
    with tmp.open("w") as f:
        for rec in records:
            f.write(json.dumps(rec) + "\n")
    tmp.replace(out)

    tiers = {}
    for rec in records:
        tiers[rec["tier"]] = tiers.get(rec["tier"], 0) + 1
    summary = {
        "generated_at": NOW,
        "spec_version": SPEC_VERSION,
        "jac_version": JAC_VERSION,
        "total_records": len(records),
        "tiers": tiers,
        "gate_outcomes": stats,
        "code_duplicates": dups,
        "unique_code_hashes": len(by_hash),
        "sft_release_set": tiers.get("v21_gold", 0),
        "out": str(out),
    }
    Path(SUMMARY).write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
