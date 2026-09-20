#!/usr/bin/env python3
"""Repair merged-corpus records whose guard (`jac test`) fails.

Continuation of the corpus-fixup line (run corpus-fixup-20260919-235830-680a2f):
fix every osp_merged_corpus record that still fails `jac check` / guard `jac
test` so the whole corpus passes the jac gates, then write the fixes back.

Failure classes (diagnosed 2026-09-20, see runs/guard_fail_pinned.pkl):
  annex_compile  v21 test annex fails to compile (E1053/E1096/E1097/E1099/
                 E1054/E1001/E1115) while candidate is clean -> fix ONLY the
                 annex; candidate must stay byte-identical; assertions keep
                 their semantics (narrow Optionals, materialize empty sets).
  candidate      behavior gap: assertions fail / runtime error (PgWire
                 Infinity, walker stops early) -> fix ONLY the candidate;
                 annex stays byte-identical.
  free           annex references symbols the candidate never defines
                 (legacy annex bugs) -> model picks the side, minimal diff.

Every gate runs with jac.toml `default_codespace = "server"` in the work dir
(spec OSP_IDIOMIZE_TASK v2.1 §2: native codespace miscompiles for-loop/f-string
appends in walker abilities and segfaults on `set()` call args; 12/12 sampled
green records stay green under the pin).

Stages:
  repair : LLM rounds per record -> artifacts under --out-dir + results.jsonl
  apply  : write fixed candidate/annex back (v21: disk files + lift row inline;
           legacy: corpus record) + patch corpus validation evidence

Usage:
  python3 scripts/ops/guard_fixup.py repair [--ids id1,id2] [--rounds 3]
  python3 scripts/ops/guard_fixup.py apply
"""
from __future__ import annotations

import argparse
import json
import os
import signal
import re
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "gen"))
sys.path.insert(0, str(REPO / "scripts" / "lib"))
import pack_merged_corpus as PMC  # noqa: E402  (JAC, strip, elimination_scan)
from llm_backend import get_backend  # noqa: E402
import generation_ledger  # noqa: E402

CORPUS = REPO / "data" / "osp_merged_corpus.jsonl"
LIFTS = REPO / "data" / "osp_lift_dataset.jsonl"
LIFT_BASE = REPO / "data" / "osp_lifts"
DEFAULT_OUT = REPO / "data" / "osp_repair" / "guard_fixup_20260920"
PIN_TOML = '[build]\ndefault_codespace = "server"\n'

JAC_FENCE = re.compile(r"```jac[^\n]*\n(.*?)```", re.S)
# marked blocks: ```jac candidate / ```jac tests
BLOCK = re.compile(r"```jac[ \t]*(candidate|tests|unchanged)[^\n]*\n(.*?)```", re.S)

ERR_TAIL = 3500  # failing-output chars fed to the model

SYSTEM = """You are a Jac 0.36.1 repair expert. You fix dataset records so their
hidden guard tests pass. Rules:
- Output FULL replacement files, never diffs or snippets.
- Keep every assertion's semantics: make the CODE satisfy the test, or fix only
  mechanical defects in the test (type errors, undefined names) without
  weakening what is asserted.
- Preserve the idiomized Jac style: nodes/edges/walkers, typed edges
  (visit [->:T:->]), no adjacency dicts, no visited-set machinery.
Jac 0.36.1 facts (verified):
- Optional narrowing is required: `x = find(...); if x is None { return ...; }`
  before using x. Attribute access on Optional fails check (E1099).
- Connection operands must be definite node instances (E1096/E1097): narrow
  first, then `a +>:E:+> b;` / `a del ->:E:-> b;`.
- `{}` is a dict literal; a set[str] parameter needs an explicit set:
  `xs: set[str] = set();` then pass xs (E1053).
- NEVER call `set()` as an inline call argument (runtime segfault) — bind it to
  a typed local first. Same for any builtin call producing a set used directly.
- `pass;` does not exist; use a comment or real statement.
- Walkers have NO built-in once-per-node visitation; add explicit guards if the
  behavior needs them. `visit [...] else { disengage; }` only ends dead ends.
- A walker ability runs on EVERY entry match; use `skip;` to skip one node.
- Graph state persists across tests in one run: each test must build its own
  fresh subgraph (attach to root or fresh nodes), never rely on another test.
Return format (exact):
```jac candidate
<full candidate file>
```
```jac tests
<full test annex file>
```
Use `unchanged` as the marker instead of copying a side you did not modify."""

CLASS_RULES = {
    "annex_compile": (
        "The CANDIDATE is clean and must stay BYTE-IDENTICAL. Fix ONLY the test "
        "annex so it compiles under jac 0.36.1 (see facts). Keep every assertion "
        "and its expected values exactly; only add narrowing locals, materialize "
        "sets, or restructure the same checks."),
    "candidate": (
        "The TEST ANNEX is authoritative and must stay BYTE-IDENTICAL. Change "
        "ONLY the candidate so all tests pass. Keep the public façade API and "
        "the Jac idioms; fix the behavior the tests demand."),
    "free": (
        "Minimal change to make all tests pass. Prefer fixing the candidate; "
        "only if the annex itself is defective (references undefined symbols, "
        "type errors) fix the annex while preserving asserted behavior."),
}

# Verified workaround for the 0.36.1 runtime bug where a walker-attached
# `can X with <Node> entry` ability silently stops firing once the same walker
# class has entered ~3+ nodes in one process (shared root across guard tests).
# Moving the ability onto the node as `can X with <Walker> entry` keeps firing.
HINT_ABILITY_MOVE = (
    "KNOWN RUNTIME BUG + VERIFIED WORKAROUND: a walker-attached entry ability "
    "(`can watch with Animal entry { ... }` inside `walker SchoolGroup`) stops "
    "firing after earlier guard tests made another walker enter several Animal "
    "nodes. Move the ability body onto the NODE archetype instead, e.g.\n"
    "  node Animal {\n"
    "      ...\n"
    "      can watch with SchoolGroup entry {\n"
    "          print(f\"Grade {visitor.grade} watches {here.name} the {here.species}\");\n"
    "          visit [-->];\n"
    "      }\n"
    "  }\n"
    "(the entering walker is bound to `visitor`; `here` is the node). Keep one "
    "such node-attached ability per (node, walker) pair and keep the print text "
    "byte-identical to what the tests assert. Remove the now-dead abilities from "
    "the walker. This exact transform already fixed sibling records.")

HINT_PERSIST = (
    "KNOWN RUNTIME FACT: jac persists node `has` fields through a JSON-backed "
    "store; float('inf')/float('nan') values abort persistence with PgWireError "
    "\"Token \\\"Infinity\\\" is invalid\". Never attach non-finite floats to "
    "nodes. For 'fails closed on non-finite input' semantics: validate BEFORE "
    "building/storing any node state, and return/raise the schema report without "
    "touching the graph.")

HINTS: list[tuple[str, str]] = [
    ("osp_B_32__", HINT_ABILITY_MOVE),
    ("osp_B_39", HINT_ABILITY_MOVE),
    ("iss_ContextualWisdomLab", HINT_PERSIST),
]


def classify(rec: dict, fail_out: str) -> str:
    if rec["corpus_ns"] == "v21":
        return "annex_compile"  # all 13 v21 fails are annex compile errors
    if "NameError" in fail_out or "IndexError" in fail_out:
        return "free"
    return "candidate"


# ----------------------------------------------------------------- gate (pinned)

def _jac_run(cmd: list[str], work: Path, timeout: int = 220) -> tuple[int, str]:
    """Process-group execution with group kill on timeout (jac leaves
    orphaned grandchildren that hold the stdout pipe)."""
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                         text=True, cwd=work, start_new_session=True)
    try:
        out_s, err_s = p.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        p.kill()
        p.communicate()
        return 124, "timeout"
    return p.returncode, (out_s or "") + (err_s or "")


def gate(rec: dict, cand: str, tests: str) -> tuple[str, str]:
    """(status, output) with server codespace pinned; status in pass/fail/timeout."""
    work = Path(tempfile.mkdtemp(prefix="gfix_"))
    (work / "jac.toml").write_text(PIN_TOML)
    if rec["corpus_ns"] == "legacy":
        try:
            stripped, _ = PMC.strip_top_level_with_entry(cand)
        except ValueError:
            return "fail", "candidate no longer strippable for legacy guard"
        (work / "main.jac").write_text(stripped)
        (work / "main.test.jac").write_text(tests)
        cmd = [PMC.JAC, "test", "main.jac"]
    else:
        (work / "guard.jac").write_text(cand + tests)
        cmd = [PMC.JAC, "test", "guard.jac"]
    rc, out = _jac_run(cmd, work)
    return ("pass" if rc == 0 else "fail"), out


def check_clean(rec: dict, cand: str) -> tuple[bool, str]:
    work = Path(tempfile.mkdtemp(prefix="gfixchk_"))
    (work / "jac.toml").write_text(PIN_TOML)
    (work / "main.jac").write_text(cand)
    rc, out = _jac_run([PMC.JAC, "check", "main.jac"], work, timeout=180)
    return rc == 0, out


# --------------------------------------------------------------------- prompting

def build_user(rec: dict, cand: str, tests: str, fail_out: str, cls: str) -> str:
    hints = "\n\n".join(h for pat, h in HINTS if pat in rec["id"])
    lines = [
        f"Record: {rec['id']} (ns={rec['corpus_ns']}, tier={rec['tier']})",
        f"Failure class: {cls}",
        "", f"CLASS RULES: {CLASS_RULES[cls]}", "",
    ]
    if hints:
        lines += [f"RECORD-SPECIFIC HINT:\n{hints}", ""]
    lines += [
        "=== CURRENT CANDIDATE (candidate_osp_jac) ===",
        cand, "",
        "=== TEST ANNEX (jac_tests) ===",
        tests or "(empty)", "",
        "=== FAILING GUARD OUTPUT (tail) ===",
        fail_out[-ERR_TAIL:], "",
        "Return the full repaired files in the exact fenced format.",
    ]
    return "\n".join(lines)


def parse_reply(text: str, old_cand: str, old_tests: str,
                cls: str) -> tuple[str, str] | None:
    blocks = {m.group(1): m.group(2) for m in BLOCK.finditer(text)}
    cand = blocks.get("candidate", "").strip()
    tests = blocks.get("tests", "").strip()
    if not blocks:
        m = JAC_FENCE.search(text)  # unmarked fallback: assume the broken side
        if not m:
            return None
        blob = m.group(1).strip()
        cand, tests = (blob, "unchanged") if cls == "candidate" else ("unchanged", blob)
    if cand in ("", "unchanged"):
        cand = old_cand
    if tests in ("", "unchanged"):
        tests = old_tests
    if cls == "annex_compile" and cand != old_cand:
        cand = old_cand  # class invariant: candidate untouched
    if cls == "candidate" and tests != old_tests:
        tests = old_tests
    return cand, tests


# ----------------------------------------------------------------------- repair

def repair_one(rec: dict, fail_out: str, args, backend, run_id: str) -> dict:
    rid = rec["id"]
    cand, tests = rec["candidate_osp_jac"] or "", rec["jac_tests"] or ""
    cls = classify(rec, fail_out)
    out_dir = Path(args.out_dir) / rid
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "candidate_orig.jac").write_text(cand)
    (out_dir / "tests_orig.jac").write_text(tests)
    res = {"id": rid, "class": cls, "rounds": [], "outcome": "unrepaired"}
    for rnd in range(1, args.rounds + 1):
        user = build_user(rec, cand, tests, fail_out, cls)
        text, err, usage = backend.call(SYSTEM, user, args.model,
                                        timeout=args.timeout, tries=2)
        generation_ledger.record_call(
            run_id, pipeline="guard-fixup", status="ok" if text else "error",
            batch=rid, model=args.model, usage=usage, error=err)
        if not text:
            res["rounds"].append({"round": rnd, "error": err})
            continue
        parsed = parse_reply(text, cand, tests, cls)
        if parsed is None:
            res["rounds"].append({"round": rnd, "error": "no fenced block in reply"})
            continue
        cand2, tests2 = parsed
        elim = PMC.elimination_scan(cand2, rec.get("source_code"))
        if not elim["clean"]:
            res["rounds"].append({"round": rnd, "error": f"elimination hits {elim['candidate_hits']}"})
            continue
        ok, chk = check_clean(rec, cand2)
        if not ok:
            fail_out = chk  # next round sees the check error instead
            res["rounds"].append({"round": rnd, "error": "jac check failed", "detail": chk[-800:]})
            (out_dir / f"round{rnd}_reply.jac").write_text(text)
            continue
        status, out = gate(rec, cand2, tests2)
        res["rounds"].append({"round": rnd, "gate": status, "out_tail": out[-1500:]})
        if status == "pass":
            res.update(outcome="repaired", candidate=cand2, tests=tests2)
            (out_dir / "candidate_fixed.jac").write_text(cand2)
            (out_dir / "tests_fixed.jac").write_text(tests2)
            break
        fail_out = out
        cand, tests = cand2, tests2  # iterate from the new state
    return res


def cmd_repair(args) -> int:
    rows = [json.loads(l) for l in CORPUS.open() if l.strip()]
    by_id = {r["id"]: r for r in rows}
    if args.ids:
        want = [i.strip() for i in args.ids.split(",") if i.strip()]
    else:
        want = sorted({json.loads(l)["tag"] for l in
                       (REPO / "data" / "audit_generated_units.jsonl").open()
                       if '"osp_merged_corpus"' in l and '"guard": "fail"' in l})
    want = [i for i in want if i in by_id]
    print(f"repair targets: {len(want)}")
    backend = get_backend(args.backend, args.model)
    run_id = generation_ledger.new_run("guard-fixup", args.model,
                                       f"repair {len(want)} guard failures")
    t0 = time.time()
    results = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {}
        # seed round-0 failure output once per record (serial-ish, cheap)
        for rid in want:
            rec = by_id[rid]
            st, out = gate(rec, rec["candidate_osp_jac"] or "", rec["jac_tests"] or "")
            if st == "pass":
                results.append({"id": rid, "outcome": "already_pass"})
                print(f"  pass (fresh) {rid}")
            else:
                futs[ex.submit(repair_one, rec, out, args, backend, run_id)] = rid
        for f in as_completed(futs):
            r = f.result()
            results.append(r)
            print(f"  {r['outcome']:9} {r['id']} ({time.time()-t0:.0f}s)")
    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    with (out / "results.jsonl").open("w") as f:
        for r in results:
            f.write(json.dumps(r) + "\n")
    fixed = sum(1 for r in results if r["outcome"] == "repaired")
    print(f"repaired {fixed}/{len(results)} -> {out / 'results.jsonl'}")
    print(generation_ledger.summary(run_id))
    return 0


# ------------------------------------------------------------------------ apply

def _load_manifests() -> dict[str, dict]:
    manifests: dict[str, dict] = {}
    skip = ("_cost_", "mm", "pool_")
    for mf in sorted(LIFT_BASE.glob("*.jsonl")):
        if mf.name.startswith(skip):
            continue
        for line in mf.read_text().splitlines():
            if line.strip():
                rec = json.loads(line)
                if "candidate_file" in rec:
                    manifests[rec["id"]] = rec
    return manifests


def cmd_apply(args) -> int:
    """Merge repair passes (later dirs override earlier), patch corpus, sync
    v21 disk files + lift-row inline candidates so a re-pack reproduces this."""
    fixed: dict[str, dict] = {}
    for rdir in [Path(p) for p in args.out_dir.split(",")]:
        rp = rdir / "results.jsonl"
        for l in rp.open():
            r = json.loads(l)
            if r["outcome"] == "repaired" or r.get("outcome") == "already_pass":
                fixed[r["id"]] = r
    manifests = _load_manifests()
    rows = [json.loads(l) for l in CORPUS.open() if l.strip()]
    now = datetime.now().isoformat()
    n_corpus = n_lift = n_disk = 0
    for rec in rows:
        r = fixed.get(rec["id"])
        if not (r and r.get("candidate")):
            continue
        rec["candidate_osp_jac"] = r["candidate"]
        rec["jac_tests"] = r["tests"]
        rec["test_hash"] = PMC.sha(r["tests"], 8) if r["tests"] else None
        rec["guard_result"] = "pass"
        val = rec.get("validation") or {}
        val["guard_fixup"] = {"at": now, "class": r.get("class"),
                              "rounds": len(r.get("rounds", [])),
                              "pin": "default_codespace=server"}
        rec["validation"] = val
        n_corpus += 1
        if rec["corpus_ns"] != "v21":
            continue
        # lift-row inline candidate: packer builds v21 records from it
        for line in LIFTS.open():
            rr = json.loads(line)
            if rr["id"] == rec["id"]:
                if rr.get("candidate_osp_jac") != r["candidate"]:
                    rr["candidate_osp_jac"] = r["candidate"]
                    _rewrite_lift_row(rr)
                    n_lift += 1
                break
        # disk candidate/guard files: packer gates run on them
        m = manifests.get(rec["id"])
        if m:
            cand_p = LIFT_BASE / m["candidate_file"]
            guard_p = LIFT_BASE / m["guard_file"]
            if cand_p.exists() and guard_p.exists():
                cand_p.write_text(r["candidate"])
                guard_p.write_text(r["candidate"] + r["tests"])
                n_disk += 1
    tmp = CORPUS.with_suffix(".jsonl.fix_tmp")
    with tmp.open("w") as f:
        for rec in rows:
            f.write(json.dumps(rec) + "\n")
    tmp.replace(CORPUS)
    if _LIFT_ROW_UPDATES:
        tmp = LIFTS.with_suffix(".jsonl.fix_tmp")
        with tmp.open("w") as f:
            for line in LIFTS.open():
                if not line.strip():
                    continue
                rr = json.loads(line)
                upd = _LIFT_ROW_UPDATES.get(rr["id"])
                if upd is not None:
                    rr = upd
                f.write(json.dumps(rr) + "\n")
        tmp.replace(LIFTS)
    print(f"corpus records patched: {n_corpus}; lift rows synced: {n_lift}; "
          f"disk files synced: {n_disk}")
    n_raw, n_pass = _sync_legacy_sources(fixed)
    print(f"legacy sources synced: osp_dataset rows={n_raw}, "
          f"osp_dataset_pass rows={n_pass}")
    print("next: re-run scripts/ops/audit_all_generated.py to confirm zero fails")
    return 0


def _sync_legacy_sources(fixed: dict[str, dict]) -> tuple[int, int]:
    """Legacy records are rebuilt from osp_dataset.jsonl (candidate fence) and
    osp_dataset_pass.jsonl (jac_tests) on repack — keep both in sync."""
    n_raw = n_pass = 0
    raw_updates: dict[str, str] = {}     # id -> new candidate
    pass_updates: dict[str, str] = {}    # id -> new jac_tests
    for rid, r in fixed.items():
        rec = _corpus_rec(rid)
        if rec is None or rec["corpus_ns"] != "legacy":
            continue
        cand = r.get("candidate")
        tests = r.get("tests")
        src_cand = _orig_candidate(rec)
        if cand and src_cand and cand != src_cand:
            raw_updates[rid] = cand
        if tests:
            snap = _pass_jac_tests(rid)
            if tests != snap:
                pass_updates[rid] = tests
    if raw_updates:
        tmp = PMC.LEGACY_RAW.with_suffix(".jsonl.fix_tmp")
        with tmp.open("w") as f, PMC.LEGACY_RAW.open() as src:
            for line in src:
                if not line.strip():
                    continue
                row = json.loads(line)
                new_cand = raw_updates.get(row["id"])
                if new_cand and len(row.get("messages", [])) > 1:
                    row["messages"][1]["content"] = PMC.JAC_FENCE.sub(
                        lambda m: "```jac\n" + new_cand + "\n```",
                        row["messages"][1]["content"] or "", count=1)
                    n_raw += 1
                f.write(json.dumps(row) + "\n")
        tmp.replace(PMC.LEGACY_RAW)
    if pass_updates:
        tmp = PMC.LEGACY_PASS.with_suffix(".jsonl.fix_tmp")
        with tmp.open("w") as f, PMC.LEGACY_PASS.open() as src:
            for line in src:
                if not line.strip():
                    continue
                row = json.loads(line)
                new_tests = pass_updates.get(row["id"])
                if new_tests is not None and row.get("jac_tests") != new_tests:
                    row["jac_tests"] = new_tests
                    n_pass += 1
                f.write(json.dumps(row) + "\n")
        tmp.replace(PMC.LEGACY_PASS)
    return n_raw, n_pass


def _corpus_rec(rid: str) -> dict | None:
    for line in CORPUS.open():
        r = json.loads(line)
        if r["id"] == rid:
            return r
    return None


def _pass_jac_tests(rid: str) -> str:
    for line in PMC.LEGACY_PASS.open():
        if not line.strip():
            continue
        r = json.loads(line)
        if r["id"] == rid:
            return r.get("jac_tests") or ""
    return ""


def _orig_candidate(rec: dict) -> str:
    """Candidate the legacy source currently yields (first jac fence of the
    assistant message) — reused as drift check."""
    row = None
    for line in PMC.LEGACY_RAW.open():
        rr = json.loads(line)
        if rr["id"] == rec["id"]:
            row = rr
            break
    if row is None or len(row.get("messages", [])) < 2:
        return ""
    m = PMC.JAC_FENCE.search(row["messages"][1]["content"] or "")
    return m.group(1).strip() if m else ""


_LIFT_ROW_UPDATES: dict[str, dict] = {}


def _rewrite_lift_row(row: dict) -> None:
    """Defer lift-row rewrite until corpus pass completes (single file rewrite)."""
    _LIFT_ROW_UPDATES[row["id"]] = row


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)
    rep = sub.add_parser("repair")
    rep.add_argument("--ids", default="", help="comma list; default = audit guard-fails")
    rep.add_argument("--model", default="composer-2.5")
    rep.add_argument("--backend", default="cursor")
    rep.add_argument("--rounds", type=int, default=3)
    rep.add_argument("--workers", type=int, default=6)
    rep.add_argument("--timeout", type=int, default=600)
    rep.add_argument("--out-dir", default=str(DEFAULT_OUT))
    rep.set_defaults(fn=cmd_repair)
    app = sub.add_parser("apply")
    app.add_argument("--out-dir", default=str(DEFAULT_OUT))
    app.set_defaults(fn=cmd_apply)
    args = ap.parse_args()
    return args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
