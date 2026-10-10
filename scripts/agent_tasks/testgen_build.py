#!/usr/bin/env python3
"""Build + validate the `testgen` agent-task pool (data/agent_tasks/testgen/).

A testgen task gives the agent WORKING Jac code and asks for a test suite.
Gates: `check` (test file compiles) + `mutation` (suite passes on the original
and kills >= threshold of a hidden, frozen mutant set). Runtime grader:
scripts/agent_tasks/testgen_grade.py.

Per-task layout (authored files marked *, generated files marked +):
  task.json+            request.md*
  starter/+             working code copied from the source task's validated
                        reference (+ source starter extras like jac.toml);
                        optional authored test stub starter_stub/<tests>* is
                        copied in for "extend the existing tests" tasks
  grader/reference/+*   code + the authored reference suite (ref_suite/<tests>*)
  grader/oracle/+       source task's own hidden tests, renamed to <tests> --
                        independent oracle used to drop equivalent mutants
  grader/trivial/+      import-only smoke suite (must FAIL the gate)
  grader/hand_mutants.json*   hand-picked semantic mutants (anchor edits)
  grader/mutant_candidates.jsonl+   sampled mechanical + hand + source negatives
  grader/mutants.jsonl+       FROZEN eligible set written by `merge` from CI
  grader/notes.md+

Subcommands:
  build                 (re)create every task in SPECS from its authored inputs
  validate --shard i/n  [CI] run every candidate mutant against the oracle /
                        reference / trivial / starter suites -> $OUT/testgen_results.jsonl
  merge <run_dir>       fold CI results in: freeze grader/mutants.jsonl, compute verdicts
  confirm --shard i/n   [CI] end-to-end: testgen_grade.py on the reference suite,
                        an empty suite and the trivial suite with the frozen set
  merge-confirm <dir>
  manifest              write manifest.jsonl (+ dedup vs evals/)
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from testgen_mutants import anchor_to_offsets, apply_mutant, find_region, generate, load_jsonl, sample  # noqa: E402
from testgen_grade import IGNORE, TaskSpec, _run, check_suite, grade, run_suite  # noqa: E402

REPO = HERE.parents[1]
ROOT = REPO / "data" / "agent_tasks" / "testgen"
AUTH = ROOT / "_authoring"            # authored inputs per task id
CACHE = ROOT / "build_results.jsonl"
CONFIRM = ROOT / "confirm_results.jsonl"
THRESHOLD = 0.8
MECH_CAP = 40
MIN_ELIGIBLE = 8
TEST_BASENAMES = ("tests.jac", "_tests.jac", ".test.jac")

# --------------------------------------------------------------------------
# Task specs. src = "<kind>/<source task id>" (validated reference, read-only).
# tests = test file the agent writes. scope = [{"file","header"}] regions to
# mutate (None = every code file). code = code files under test (default: all
# .jac in the source reference that are not test files).
# --------------------------------------------------------------------------
SPECS: list[dict] = json.loads((ROOT / "specs.json").read_text()) if (ROOT / "specs.json").exists() else []


def task_hash(task_dir: Path) -> str:
    h = hashlib.sha256()
    for p in sorted(task_dir.rglob("*")):
        rel = p.relative_to(task_dir).as_posix()
        if not p.is_file() or "__jac_gen__" in rel or "/.jac/" in rel or rel in ("grader/mutants.jsonl", "grader/notes.md"):
            continue
        if rel == "task.json":   # verdict fields are written back into task.json
            meta = json.loads(p.read_text())
            meta.get("mutation", {}).pop("stats", None)
            h.update(json.dumps(meta, sort_keys=True).encode())
            continue
        h.update(rel.encode())
        h.update(p.read_bytes())
    return h.hexdigest()[:16]


def _is_test_file(name: str) -> bool:
    return name.endswith(TEST_BASENAMES) or name.startswith("test_")


def _copy_code(src_ref: Path, dst: Path, code: list[str]) -> None:
    for f in code:
        (dst / f).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src_ref / f, dst / f)


def build_task(spec: dict) -> Path:
    tid = spec["id"]
    kind, sid = spec["src"].split("/")
    src = REPO / "data" / "agent_tasks" / kind / sid
    ref = src / "grader" / "reference"
    auth = AUTH / tid
    t = ROOT / tid
    if t.exists():
        shutil.rmtree(t)
    (t / "grader").mkdir(parents=True)
    tests = spec["tests"]
    code = spec.get("code") or sorted(
        p.relative_to(ref).as_posix() for p in ref.rglob("*.jac") if p.is_file()
        and not _is_test_file(p.name) and "__jac_gen__" not in p.parts and ".jac" not in p.relative_to(ref).parts[:-1])
    # starter = source starter extras (jac.toml, AGENTS.md ...) + reference code
    starter = t / "starter"
    starter.mkdir()
    for p in (src / "starter").rglob("*"):
        rel = p.relative_to(src / "starter")
        if p.is_file() and p.suffix != ".jac" and "__jac_gen__" not in rel.parts and ".jac" not in rel.parts:
            (starter / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(p, starter / rel)
    for p in ref.rglob("*"):
        rel = p.relative_to(ref)
        if p.is_file() and p.suffix != ".jac" and "__jac_gen__" not in rel.parts and ".jac" not in rel.parts:
            (starter / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(p, starter / rel)
    _copy_code(ref, starter, code)
    if (auth / "starter_stub").is_dir():
        shutil.copytree(auth / "starter_stub", starter, dirs_exist_ok=True)
    # reference = starter + authored reference suite
    shutil.copytree(starter, t / "grader" / "reference", dirs_exist_ok=True)
    shutil.copytree(auth / "ref_suite", t / "grader" / "reference", dirs_exist_ok=True)
    # oracle = source hidden tests under the task's test filename
    (t / "grader" / "oracle").mkdir()
    shutil.copyfile(src / "grader" / "tests.jac", t / "grader" / "oracle" / tests)
    # trivial = import-only smoke suite
    (t / "grader" / "trivial").mkdir()
    (t / "grader" / "trivial" / tests).write_text(
        f"import {spec['trivial_import']}\n\ntest \"module imports\" {{\n    assert True;\n}}\n")
    shutil.copyfile(auth / "request.md", t / "request.md")
    hand = json.loads((auth / "hand_mutants.json").read_text()) if (auth / "hand_mutants.json").exists() else []
    if (auth / "hand_mutants.json").exists():
        shutil.copyfile(auth / "hand_mutants.json", t / "grader" / "hand_mutants.json")

    # ---- candidate mutants
    ws = t / "grader" / "reference"
    regions: dict[str, list[tuple[int, int]] | None] = {}
    for f in code:
        regions[f] = None
    if spec.get("scope"):
        regions = {}
        for sc in spec["scope"]:
            src_txt = (ws / sc["file"]).read_text()
            r = (0, len(src_txt)) if sc.get("header") is None else find_region(src_txt, sc["header"])
            regions.setdefault(sc["file"], []).append(r)
    mech: list[dict] = []
    for f, regs in regions.items():
        mech += generate((ws / f).read_text(), f, regs)
    cands = sample(mech, spec.get("mech_cap", MECH_CAP), tid)

    def in_scope(edits: list[dict]) -> bool:
        for ed in edits:
            regs = regions.get(ed["file"], "missing")
            if regs == "missing":
                return False
            if regs is None:
                continue
            if not any(a <= ed["offset"] < b for a, b in regs):
                return False
        return True

    negs = src / "grader" / "negatives"
    n_src_neg = 0
    if negs.is_dir() and not spec.get("skip_source_negatives"):
        for p in sorted(negs.glob("*.json")):
            ng = json.loads(p.read_text())
            try:
                eds = anchor_to_offsets(ws, ng["edits"])
            except (ValueError, FileNotFoundError):
                continue
            if in_scope(eds):
                cands.append({"source": "source-negative", "op": f"neg {p.stem}", "why": ng.get("why", ""), "edits": eds})
                n_src_neg += 1
    for i, hm in enumerate(hand):
        eds = anchor_to_offsets(ws, hm["edits"])
        cands.append({"source": "hand", "op": f"hand {hm.get('name', i)}", "why": hm.get("why", ""), "edits": eds})
    # dedupe identical edit sets, assign ids
    seen, uniq = set(), []
    for c in cands:
        key = json.dumps(c["edits"], sort_keys=True)
        if key not in seen:
            seen.add(key)
            uniq.append(c)
    for i, c in enumerate(uniq):
        c["id"] = f"c{i:02d}"
    (t / "grader" / "mutant_candidates.jsonl").write_text("".join(json.dumps(c) + "\n" for c in uniq))

    meta = {
        "id": tid, "kind": "testgen", "level": spec["level"], "source": f"derived:{spec['src']}",
        "gates": ["check", "mutation"], "target_paths": [tests], "jac_version": TARGET_JAC,
        "license": "original-authored (jac_llm_data agent-task pool)",
        "mutation": {"threshold": THRESHOLD, "code_files": code, "scope": spec.get("scope"),
                     "n_candidates": len(uniq), "n_mechanical_sites": len(mech),
                     "n_source_negatives": n_src_neg, "n_hand": len(hand)},
        "provenance": {"source_task": spec["src"], "source_hash": _src_hash(src), "variant": spec.get("variant", "fresh"),
                       "title": spec.get("title", ""), "domain": spec.get("domain", ""),
                       "author": "claude (testgen builder)", "created": "2026-10-10"},
    }
    (t / "task.json").write_text(json.dumps(meta, indent=2) + "\n")
    return t


def _src_hash(src: Path) -> str:
    h = hashlib.sha256()
    for sub in ("grader/reference", "grader/tests.jac", "grader/negatives"):
        p = src / sub
        files = sorted(p.rglob("*")) if p.is_dir() else [p]
        for f in files:
            if f.is_file() and "__jac_gen__" not in f.parts:
                h.update(str(f.relative_to(src)).encode())
                h.update(f.read_bytes())
    return h.hexdigest()[:16]


def task_dirs() -> list[Path]:
    return sorted(p for p in ROOT.iterdir() if (p / "task.json").exists())


def load_results(*paths: Path) -> dict[str, dict]:
    latest: dict[str, dict] = {}
    for path in paths:
        for r in load_jsonl(path):
            latest[r["id"]] = r
    return latest


# ------------------------------------------------------------------ build --
def cmd_build(a) -> int:
    only = set(a.only.split(",")) if a.only else None
    for spec in SPECS:
        if only and spec["id"] not in only:
            continue
        if not (AUTH / spec["id"] / "ref_suite").is_dir():
            print(f"skip {spec['id']}: no authored ref_suite yet")
            continue
        t = build_task(spec)
        m = json.loads((t / "task.json").read_text())["mutation"]
        print(f"built {spec['id']}: {m['n_candidates']} candidates ({m['n_mechanical_sites']} mech sites, "
              f"{m['n_source_negatives']} src-neg, {m['n_hand']} hand)")
    return 0


# --------------------------------------------------------------- validate --
def validate(t: Path, jac: str, jobs: int) -> dict:
    spec = TaskSpec(t)
    g = t / "grader"
    suites = {"ref": g / "reference", "oracle": g / "oracle", "trivial": g / "trivial"}
    if any((t / "starter" / x).exists() and 'test "' in (t / "starter" / x).read_text() for x in spec.tests):
        suites["starter"] = t / "starter"
    r: dict = {"id": t.name, "hash": task_hash(t), "fail": [], "original": {}, "mutants": []}
    # code compiles
    with spec.base_workspace() as tmp:
        for f in spec.code_files:
            rc, out = _run([jac, "check", f], Path(tmp))
            if rc != 0:
                r["fail"].append(f"code {f} fails jac check: {out[-400:]}")
    ok, msg = check_suite(spec, suites["ref"], jac)
    if not ok:
        r["fail"].append(f"reference suite fails jac check: {msg}")
    for name, d in suites.items():
        passes = [run_suite(spec, d, jac, None) for _ in range(2 if name == "ref" else 1)]
        r["original"][name] = all(p[0] for p in passes)
        r.setdefault("sample_out", {})[name] = passes[0][1][-500:]
        if not r["original"][name]:
            r["fail"].append(f"{name} suite does not pass on original: {passes[0][1][-600:]}")
    if r["fail"]:
        r["validated_stage1"] = False
        return r

    def one(m: dict) -> dict:
        row = {"cid": m["id"], "op": m["op"], "source": m["source"]}
        with spec.base_workspace() as tmp:
            wd = Path(tmp)
            apply_mutant(wd, m)
            for f in sorted({e["file"] for e in m["edits"]}):
                rc, out = _run([jac, "check", f], wd)
                if rc != 0:
                    row["stillborn"] = True
                    row["err"] = out[-200:]
                    return row
        row["stillborn"] = False
        for name, d in suites.items():
            passed, _ = run_suite(spec, d, jac, m)
            row[name] = "survived" if passed else "killed"
        return row

    cands = load_jsonl(g / "mutant_candidates.jsonl")
    with cf.ThreadPoolExecutor(max_workers=jobs) as ex:
        r["mutants"] = list(ex.map(one, cands))
    r["validated_stage1"] = True
    return r


def cmd_validate(a) -> int:
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    tasks = task_dirs()
    if a.only:
        tasks = [t for t in tasks if t.name in set(a.only.split(","))]
    shard, n = (int(x) for x in a.shard.split("/"))
    tasks = [t for i, t in enumerate(tasks) if i % n == shard]
    cache = load_results(CACHE)
    with (out / "testgen_results.jsonl").open("a") as fh:
        for t in tasks:
            prev = cache.get(t.name)
            if not a.force and prev and prev.get("hash") == task_hash(t) and prev.get("validated_stage1"):
                print(f"=== {t.name}: cached, skip")
                continue
            print(f"=== {t.name}", flush=True)
            try:
                r = validate(t, a.jac, a.jobs)
            except Exception as e:
                r = {"id": t.name, "hash": task_hash(t), "fail": [f"harness error: {type(e).__name__}: {e}"],
                     "validated_stage1": False, "mutants": []}
            fh.write(json.dumps(r) + "\n")
            fh.flush()
            print(f"    fail={r['fail'][:1]} mutants={len(r['mutants'])}", flush=True)
    return 0


def verdict(t: Path, r: dict) -> dict:
    """Freeze grader/mutants.jsonl from a stage-1 result and compute rates."""
    cands = {c["id"]: c for c in load_jsonl(t / "grader" / "mutant_candidates.jsonl")}
    rows = r.get("mutants", [])
    live = [x for x in rows if not x.get("stillborn")]
    eligible = [x for x in live if "killed" in (x.get("oracle"), x.get("ref"))]
    dropped_equiv = [x["cid"] for x in live if x not in eligible]
    frozen = []
    for i, x in enumerate(eligible):
        c = dict(cands[x["cid"]])
        c["id"] = f"m{i:02d}"
        c.pop("line", None)
        frozen.append(c)
    n = len(frozen)

    def rate(name: str) -> float | None:
        if not eligible or name not in eligible[0]:
            return None
        return round(sum(x[name] == "killed" for x in eligible) / n, 4)

    st = {"n_candidates": len(rows), "n_stillborn": len(rows) - len(live), "n_presumed_equivalent": len(dropped_equiv),
          "n_eligible": n, "ref_kill": rate("ref"), "oracle_kill": rate("oracle"), "trivial_kill": rate("trivial"),
          "starter_kill": rate("starter"),
          "ref_survivors": [frozen[i]["op"] for i, x in enumerate(eligible) if x["ref"] != "killed"]}
    fails = list(r.get("fail", []))
    if not fails:
        if n < MIN_ELIGIBLE:
            fails.append(f"only {n} eligible mutants (< {MIN_ELIGIBLE})")
        if (st["ref_kill"] or 0) < THRESHOLD:
            fails.append(f"reference suite kills {st['ref_kill']} < {THRESHOLD}")
        if (st["trivial_kill"] or 0) >= THRESHOLD:
            fails.append(f"trivial suite kills {st['trivial_kill']} >= {THRESHOLD}")
        if st["starter_kill"] is not None and st["starter_kill"] >= THRESHOLD:
            fails.append(f"starter's existing tests already kill {st['starter_kill']} >= {THRESHOLD}")
    return {"frozen": frozen, "stats": st, "fails": fails, "dropped_equiv": dropped_equiv}


def cmd_merge(a) -> int:
    files = sorted(Path(a.run_dir).rglob("testgen_results.jsonl"))
    merged = load_results(CACHE)
    n = 0
    for f in files:
        for r in load_jsonl(f):
            r["ci_run"] = a.run_id or Path(a.run_dir).name
            merged[r["id"]] = r
            n += 1
    CACHE.write_text("".join(json.dumps(merged[k]) + "\n" for k in sorted(merged)))
    print(f"merged {n} results from {len(files)} files")
    for t in task_dirs():
        r = merged.get(t.name)
        if not r or r["hash"] != task_hash(t):
            continue
        v = verdict(t, r)
        (t / "grader" / "mutants.jsonl").write_text("".join(json.dumps(m) + "\n" for m in v["frozen"]))
        meta = json.loads((t / "task.json").read_text())
        meta["mutation"]["stats"] = v["stats"]
        (t / "task.json").write_text(json.dumps(meta, indent=2) + "\n")
        notes = [f"# {t.name}", "", f"Source: {meta['source']} (validated reference; oracle = its hidden tests).",
                 f"Gate: suite must pass on original and kill >= {THRESHOLD:.0%} of grader/mutants.jsonl.", "",
                 "Mutant stats (CI " + str(r.get("ci_run")) + "): " + json.dumps(v["stats"]),
                 "", "Presumed-equivalent candidates (survived oracle AND reference, dropped): " + ", ".join(
                     f"{c}" for c in v["dropped_equiv"]) or "none"]
        if v["fails"]:
            notes += ["", "NOT VALIDATED: " + "; ".join(v["fails"])]
        (t / "grader" / "notes.md").write_text("\n".join(notes) + "\n")
        print(f"{t.name}: eligible={v['stats']['n_eligible']} ref={v['stats']['ref_kill']} "
              f"oracle={v['stats']['oracle_kill']} trivial={v['stats']['trivial_kill']} "
              f"starter={v['stats']['starter_kill']} {'OK' if not v['fails'] else 'FAIL ' + '; '.join(v['fails'])[:200]}")
    return 0


# ---------------------------------------------------------------- confirm --
def confirm(t: Path, jac: str, jobs: int) -> dict:
    """End-to-end through the real grader with the frozen set."""
    out = {"id": t.name, "hash": task_hash(t)}
    ref = grade(t, t / "grader" / "reference", jac, jobs)
    out["ref"] = {k: ref.get(k) for k in ("passed", "kill_rate", "survived", "reason")}
    with tempfile.TemporaryDirectory() as e:
        out["empty"] = {k: v for k, v in grade(t, Path(e), jac, jobs).items() if k in ("passed", "reason")}
        spec = TaskSpec(t)
        for x in spec.tests:
            (Path(e) / x).write_text("")
        out["empty_file"] = {k: v for k, v in grade(t, Path(e), jac, jobs).items() if k in ("passed", "reason")}
        for x in spec.tests:   # suite whose import fails: 0.36/0.37 `jac test` may exit 0 ("skipped")
            (Path(e) / x).write_text("import from no_such_module_xyz { Nope }\n\ntest \"probe\" {\n    assert Nope is not None;\n}\n")
        bi_pass, bi_out = run_suite(spec, Path(e), jac, None)   # bypass the check gate on purpose
        out["bad_import"] = {"passed": bi_pass, "out": bi_out[-300:]}
    triv = grade(t, t / "grader" / "trivial", jac, jobs)
    out["trivial"] = {k: triv.get(k) for k in ("passed", "kill_rate")}
    out["confirmed"] = bool(ref["passed"]) and not out["empty"]["passed"] and not out["empty_file"]["passed"] and not out["bad_import"]["passed"] and not triv["passed"]
    return out


def cmd_confirm(a) -> int:
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    tasks = [t for t in task_dirs() if (t / "grader" / "mutants.jsonl").exists()]
    if a.only:
        tasks = [t for t in tasks if t.name in set(a.only.split(","))]
    shard, n = (int(x) for x in a.shard.split("/"))
    tasks = [t for i, t in enumerate(tasks) if i % n == shard]
    with (out / "testgen_confirm.jsonl").open("a") as fh:
        for t in tasks:
            print(f"=== confirm {t.name}", flush=True)
            try:
                r = confirm(t, a.jac, a.jobs)
            except Exception as e:
                r = {"id": t.name, "hash": task_hash(t), "confirmed": False, "error": f"{type(e).__name__}: {e}"}
            fh.write(json.dumps(r) + "\n")
            fh.flush()
            print("   ", json.dumps(r)[:300], flush=True)
    return 0


def cmd_merge_confirm(a) -> int:
    merged = load_results(CONFIRM)
    for f in sorted(Path(a.run_dir).rglob("testgen_confirm.jsonl")):
        for r in load_jsonl(f):
            r["ci_run"] = a.run_id or Path(a.run_dir).name
            merged[r["id"]] = r
    CONFIRM.write_text("".join(json.dumps(merged[k]) + "\n" for k in sorted(merged)))
    for k in sorted(merged):
        print(k, merged[k].get("confirmed"), merged[k].get("ref", {}).get("kill_rate"), merged[k].get("error", ""))
    return 0


# --------------------------------------------------------------- manifest --
def cmd_manifest(a) -> int:
    sys.path.insert(0, str(HERE))
    import native_dedup as nd
    results = load_results(CACHE)
    confirms = load_results(CONFIRM)
    tasks = task_dirs()
    dd = nd.dedup_all(tasks)
    src_status = source_status()
    lines = []
    for t in tasks:
        meta = json.loads((t / "task.json").read_text())
        h = task_hash(t)
        r, c, d = results.get(t.name), confirms.get(t.name), dd[t.name]
        st = meta["mutation"].get("stats", {})
        src_ok, src_why = src_status.get(meta["provenance"]["source_task"], (False, "unknown source"))
        if meta["provenance"].get("source_hash") != _src_hash(REPO / "data" / "agent_tasks" / meta["provenance"]["source_task"]):
            src_ok, src_why = False, "source task changed since build (rebuild)"
        if r is None:
            validated, reason = False, "not yet validated"
        elif r["hash"] != h:
            validated, reason = False, f"stale result (hash {r['hash']} != {h})"
        else:
            fails = verdict(t, r)["fails"]
            if fails:
                validated, reason = False, "; ".join(x.splitlines()[0] for x in fails)[:400]
            elif not c or c.get("hash") != h or not c.get("confirmed"):
                validated, reason = False, "grader end-to-end confirm missing/failed" + (f": {c}" if c and c.get("hash") == h else "")
            elif not d["clean"]:
                validated, reason = False, f"dedup: {d['reason']}"
            elif not src_ok:
                validated, reason = False, f"source not validated: {src_why}"
            else:
                validated = True
                reason = (f"ref suite kills {st['ref_kill']:.0%} of {st['n_eligible']} mutants "
                          f"(oracle {st['oracle_kill']:.0%}, trivial {st['trivial_kill']:.0%}"
                          + (f", starter {st['starter_kill']:.0%}" if st.get('starter_kill') is not None else "")
                          + f"); {st['n_stillborn']} stillborn + {st['n_presumed_equivalent']} presumed-equivalent dropped; "
                          "grader confirmed (ref pass, empty/trivial fail)")
        lines.append({"id": meta["id"], "level": meta["level"], "source": meta["source"], "gates": meta["gates"],
                      "validated": validated, "reason": reason, "hash": h, "ci_run": (r or {}).get("ci_run"),
                      "confirm_run": (c or {}).get("ci_run"), "stats": st, "dedup": d})
    (ROOT / "manifest.jsonl").write_text("".join(json.dumps(x) + "\n" for x in lines))
    by: dict = {}
    for x in lines:
        by.setdefault(x["level"], [0, 0])
        by[x["level"]][0] += 1
        by[x["level"]][1] += x["validated"]
    print("level  tasks  validated")
    for lv in sorted(by):
        print(f"  L{lv}   {by[lv][0]:5d}  {by[lv][1]:9d}")
    print(f"  all  {len(lines):5d}  {sum(x['validated'] for x in lines):9d}")
    for x in lines:
        if not x["validated"]:
            print(f"  - {x['id']}: {x['reason'][:220]}")
    return 0


TARGET_JAC = "0.36.1"


def source_status() -> dict[str, tuple[bool, str]]:
    """Is each source task's reference validated by its own builder AT TARGET_JAC?
    native: manifest.jsonl (verdict) + build_results.jsonl ("jac" version string);
    app: manifest.jsonl ("validated_with" / "jac_version")."""
    out: dict[str, tuple[bool, str]] = {}
    for kind in ("native", "app"):
        d = REPO / "data" / "agent_tasks" / kind
        ver: dict[str, str] = {}
        for r in load_jsonl(d / "build_results.jsonl"):
            ver[r["id"]] = str(r.get("jac") or r.get("jac_version") or "")
        for r in load_jsonl(d / "manifest.jsonl"):
            v = str(r.get("jac_version") or r.get("validated_with") or r.get("jac") or ver.get(r["id"], ""))
            ok = bool(r.get("validated")) and TARGET_JAC in v
            why = str(r.get("reason") or "") if not r.get("validated") else (f"validated with {v!r}, need {TARGET_JAC}" if not ok else "")
            out[f"{kind}/{r['id']}"] = (ok, why)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    b = sp.add_parser("build")
    b.add_argument("--only", default="")
    for name in ("validate", "confirm"):
        v = sp.add_parser(name)
        v.add_argument("--shard", default="0/1")
        v.add_argument("--out", default=str(ROOT / "_local_out"))
        v.add_argument("--jac", default="jac")
        v.add_argument("--jobs", type=int, default=3)
        v.add_argument("--only", default="")
        v.add_argument("--force", action="store_true")
    for name in ("merge", "merge-confirm"):
        m = sp.add_parser(name)
        m.add_argument("run_dir")
        m.add_argument("--run-id", default="")
    sp.add_parser("manifest")
    a = ap.parse_args()
    return {"build": cmd_build, "validate": cmd_validate, "merge": cmd_merge, "confirm": cmd_confirm,
            "merge-confirm": cmd_merge_confirm, "manifest": cmd_manifest}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
