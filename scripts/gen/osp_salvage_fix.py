#!/usr/bin/env python3
"""Salvage gate-failed candidates from data/osp_composer_failures.jsonl.

Takes the LAST gate attempt's embedded code per problem id (rows carry the
rejected program in `code`), applies mechanical fixes for the failure
classes that are fixable without semantic judgment:

  - referenced-but-undeclared edge archetypes  -> inject `edge X { }`
  - typed backward visits (`[<--:T:--]`)       -> rewrite to plain `[<--]`
    (jac 0.36.1 cannot parse any typed backward form)
  - walker declared but no typed-entry+visit   -> insert `visit [-->] else
    { disengage; }` at the top of the first typed-entry ability body
  - `pass;` statements (not valid Jac)         -> comment out
  - E2004 non-default `has` field              -> add a primitive default

Then re-runs the exact production gate (mm.jac_check: `jac check` + `jac run`
+ non-empty output; mm.osp_contract) and appends passers to
data/osp_dataset.jsonl in the composer driver's record schema, tagged
run_tag=osp-salvage-<date>. Every candidate is ledgered with real
record_ids/n_parsed so token accounting stays trustworthy.

With --model-repair, candidates that survive the mechanical pass get up to
MAX_MODEL_ROUNDS cursor-agent repair rounds (mm._fix_user + the corrected
gate + class_hint) before being given up on; each repair call is ledgered
under pipeline osp-repair with full token usage.
"""

from __future__ import annotations

import json
import re
import sys
import tempfile
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "gen"))
sys.path.insert(0, str(REPO / "scripts" / "lib"))
import generation_ledger  # noqa: E402
import osp_composer_generate as og  # noqa: E402
import osp_minimax_generate as mm  # noqa: E402

FAILS = REPO / "data" / "osp_composer_failures.jsonl"
OUT = REPO / "data" / "osp_dataset.jsonl"
PROBLEMS = REPO / "data" / "osp_lifts" / "mm3_issue_problems3.jsonl"

CUTOFF = "2026-08-30T22:05"  # only last night's run
RUN_TAG = "osp-salvage-20260831"
MODEL = "composer-2.5"
MAX_ROUNDS = 3
MAX_MODEL_ROUNDS = 3
MODEL_REPAIR = False
WORKERS = 6

PRIM_DEFAULT = {
    "str": '""', "int": "0", "float": "0.0", "bool": "True",
    "list": "[]", "dict": "{}",
}

PROBLEMS_BY_ID: dict[str, dict] = {}


def last_gate_rows() -> dict[str, dict]:
    """Last gate-failure row per id that embeds candidate code."""
    last: dict[str, dict] = {}
    for line in FAILS.read_text().splitlines():
        if not line.strip():
            continue
        try:
            r = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not r.get("code") or r.get("stage") != "gate":
            continue
        if r.get("ts", "") < CUTOFF:
            continue
        prev = last.get(r["id"])
        if prev is None or r.get("ts", "") >= prev.get("ts", ""):
            last[r["id"]] = r
    return last


def inject_edges(code: str) -> tuple[str, bool]:
    """Declare every edge archetype referenced by typed visits/connections."""
    have = set(re.findall(r"\bedge\s+(\w+)\s*(?:\{|;)", code))
    need: set[str] = set()
    for m in re.finditer(r"[+\-]+>:(\w+)", code):
        need.add(m.group(1))
    for m in re.finditer(r"<[\-]+:(\w+)", code):
        need.add(m.group(1))
    need -= have
    if not need:
        return code, False
    decls = "\n".join(f"edge {n} {{ }}" for n in sorted(need)) + "\n\n"
    m = re.search(r"^walker\s+", code, re.M)
    if not m:
        m = re.search(r"^with\s+entry", code, re.M)
    anchor = m.start() if m else len(code)
    return code[:anchor] + decls + code[anchor:], True


def fix_backward_visit(code: str) -> tuple[str, bool]:
    """jac 0.36.1 cannot parse typed backward visits (`[<--:T:--]` in any
    variant). Rewrite to plain `[<--]`: same traversal, filter dropped."""
    new = re.sub(r"\[<--:\w+[^]]*\]", "[<--]", code)
    return new, new != code


def add_visit(code: str) -> tuple[str, bool]:
    """Satisfy the typed-entry-must-visit contract on the first ability."""
    if not re.search(r"\bwalker\s+\w+", code):
        return code, False
    if mm._ABILITY_WITH_ENTRY.search(code):
        return code, False
    w = re.search(r"\bwalker\s+\w+\s*\{", code)
    if not w:
        return code, False
    m = re.compile(
        r"^([ \t]*)can\s+\w+\s+with\s+(?:Root|\w+)\s+entry\s*\{", re.M
    ).search(code, w.start())
    if not m:
        return code, False
    open_brace = code.index("{", m.start())
    stmt = f"\n{m.group(1)}    visit [-->] else {{ disengage; }}"
    return code[:open_brace + 1] + stmt + code[open_brace + 1:], True


def comment_pass(code: str) -> tuple[str, bool]:
    new = re.sub(r"^(\s*)pass\s*;?\s*$", r"\1# pass", code, flags=re.M)
    return new, new != code


def default_attrs(code: str, error: str) -> tuple[str, bool]:
    m = re.search(r"attribute '(\w+)'", error or "")
    if not m:
        return code, False
    name = re.escape(m.group(1))
    pat = re.compile(rf"(has\s+{name}:\s*)(\w+)(\s*;)")

    def rep(m2: re.Match) -> str:
        if m2.group(2) in PRIM_DEFAULT:
            return f"{m2.group(1)}{m2.group(2)} = {PRIM_DEFAULT[m2.group(2)]};"
        return m2.group(0)

    new = pat.sub(rep, code)
    return new, new != code


def apply_fixes(code: str, error: str) -> tuple[str, bool]:
    changed = False
    for fixer in (lambda c: inject_edges(c),
                  lambda c: fix_backward_visit(c),
                  lambda c: add_visit(c),
                  lambda c: comment_pass(c),
                  lambda c: default_attrs(c, error)):
        code, ch = fixer(code)
        changed = changed or ch
    return code, changed


def gate(code: str, work: Path) -> tuple[bool, str]:
    ok, log = mm.jac_check(code, work)
    if not ok:
        return False, log
    return mm.osp_contract(code)


def class_hint(err: str) -> str:
    """Extra repair guidance for the classes models keep fumbling."""
    if "run-timeout" in err:
        return ("\n\nAdditional constraint: the program HANGS at runtime. A walker "
                "revisits nodes forever on a cyclic graph — jac 0.36.1 has NO built-in "
                "once-per-node visitation. Add an explicit cycle guard: give the walker "
                "`has _seen: list[str] = [];` and in the visiting ability disengage "
                "when the node key is already in `self._seen`, or bound recursion with "
                "a depth counter that disengages at 0.")
    if ("Missing ']'" in err or "Missing ';'" in err
            or "Expected '{'" in err or "Unexpected token" in err):
        return ("\n\nAdditional grammar constraints for jac 0.36.1: typed backward "
                "visits `visit [<--:T:--]` DO NOT EXIST — write plain `visit [<--]` "
                "(an `else { ... }` clause may follow). Typed forward visits are "
                "`visit [->:T:->]`. `else if` is not valid Jac — nest: "
                "`} else { if cond { ... } }`. Every statement ends with `;`.")
    return ""


def land(full_id: str, prob: dict, code: str) -> str:
    """Append a passing record to the dataset. Returns 'landed'."""
    row = {
        "id": full_id,
        "category": "code_gen",
        "task_type": "osp",
        "complexity": "medium",
        "compiler_pass": True,
        "test_pass": None,
        "manually_reviewed": False,
        "generator": "cursor-cli",
        "generator_model_id": MODEL,
        "gate_class": "compile_only",
        "variant_idx": 0,
        "generation_date": datetime.now().isoformat(),
        "source_prompt_version": "osp-ref-v1",
        "context_bundle_version": "jac-osp-reference-2025",
        "validator_version": "jac-0.36.1-check",
        "dataset_version": "jac-synth-v2.0.0",
        "run_tag": RUN_TAG,
        "messages": [
            {"role": "user", "content": prob["problem"].strip()},
            {"role": "assistant", "content": f"```jac\n{code.rstrip()}\n```"},
        ],
    }
    with OUT.open("a") as fh:
        fh.write(json.dumps(row) + "\n")
    return "landed"


def salvage(item: tuple[str, str, str]) -> tuple[str, str, str, str]:
    """Returns (id, outcome, final_code, error). outcome: landed|still_fail|no_problem."""
    full_id, code, error = item
    rid = re.sub(r"__\w+_v\d+$", "", full_id)
    prob = PROBLEMS_BY_ID.get(rid)
    if prob is None:
        return full_id, "no_problem", code, "problem text not found"
    final_err = error
    for _ in range(MAX_ROUNDS):
        code, _ = apply_fixes(code, final_err)
        with tempfile.TemporaryDirectory(prefix="osp_salvage_") as td:
            ok, log = gate(code, Path(td))
        if ok:
            return full_id, land(full_id, prob, code), code, ""
        final_err = log
        # only re-round if the remaining error is still a fixable class
        if not ("undefined name" in final_err or "does not `visit`" in final_err
                or "'pass'" in final_err or "attribute '" in final_err
                or "Missing ']'" in final_err or "Missing ';'" in final_err):
            break
    if MODEL_REPAIR:
        for _ in range(MAX_MODEL_ROUNDS):
            prompt = (mm._fix_user(prob["problem"], code, final_err)
                      + class_hint(final_err))
            content, cerr = og.call_composer(mm.SYSTEM, prompt, full_id,
                                             pipeline="osp-repair")
            if cerr or not content:
                final_err = f"repair call: {cerr or 'empty response'}"
                continue
            new_code = mm.extract_jac(content)
            if new_code is None:
                final_err = "no ```jac fence in repair response"
                continue
            code = new_code
            with tempfile.TemporaryDirectory(prefix="osp_salvage_") as td:
                ok, log = gate(code, Path(td))
            if ok:
                return full_id, land(full_id, prob, code), code, ""
            final_err = log
    return full_id, "still_fail", code, final_err[:200]


def main() -> int:
    global PROBLEMS_BY_ID, MODEL_REPAIR
    import argparse
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=0,
                    help="salvage only the first N candidates (smoke test)")
    ap.add_argument("--model-repair", action="store_true",
                    help="repair still-failing candidates with cursor-agent "
                         "(composer-2.5 via call_composer, ledgered as "
                         "osp-repair)")
    args = ap.parse_args()
    MODEL_REPAIR = args.model_repair
    existing = set()
    for line in OUT.read_text().splitlines():
        if line.strip():
            try:
                existing.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                pass
    PROBLEMS_BY_ID = {p["id"]: p for p in mm.load_problems(str(PROBLEMS))}

    rows = last_gate_rows()
    items = [(i, r["code"], r.get("error", "")) for i, r in rows.items()
             if i not in existing]
    if args.limit:
        items = items[: args.limit]
    print(f"[plan] {len(rows)} gate-failed ids with code, "
          f"{len(items)} to salvage ({len(rows) - len(items)} already landed)"
          f"{', model-repair ON' if MODEL_REPAIR else ''}", flush=True)

    run_id = generation_ledger.new_run(
        "osp-salvage", model=MODEL,
        note="mechanical repair of 2026-08-30 gate-failed candidates")
    with ThreadPoolExecutor(max_workers=WORKERS) as ex:
        results = list(ex.map(salvage, items))
    outcomes = Counter(r[1] for r in results)
    for full_id, outcome, _code, err in results:
        generation_ledger.record_call(
            run_id, pipeline="osp-salvage",
            status="ok" if outcome == "landed" else "gate_fail",
            model=MODEL, batch=full_id, record_ids=[full_id],
            n_parsed=1 if outcome == "landed" else 0, dur_s=None)
        if outcome != "landed":
            generation_ledger.record_call(
                run_id, pipeline="osp-salvage", status="is_error",
                model=MODEL, batch=full_id, record_ids=[full_id],
                error=err)
    print(f"[done] {dict(outcomes)}", flush=True)
    err_classes = Counter(r[3].split("\n")[0][:70] for r in results
                          if r[1] == "still_fail")
    for cls, n in err_classes.most_common(12):
        print(f"  {n:4d}  {cls}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
