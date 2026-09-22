#!/usr/bin/env python3
"""Behavioral gate for FARM->Jac CRUD walkers.

Replaces `jac check` (syntactic, passes hollow stubs) as the keep signal. Given a
candidate .jac (node archetypes + CRUD walkers) and a manifest describing which
walker is create/list/update/delete for a node type, this:

  1. jac check      -- cheap syntactic pre-gate
  2. build a delta-based CRUD probe (`with entry {...}`) from the manifest
  3. jac run candidate+probe, assert real persistence deltas:
       create -> +1 findable node   (hollow `report X` without ++> fails: delta 0)
       update -> the asserted field actually flips in re-read state
       delete -> node gone, count back to baseline (no-op delete fails)

Deltas, not absolute counts: the default Jac store (~/.cache/jac/pg) persists across
runs, so absolute-count asserts are unstable; deltas are robust and are exactly what
distinguish faithful CRUD from hollow/no-op stubs.

Manifest (JSON):
{
  "node": "Todo",
  "tag_field": "title",                       # field used to find "our" node
  "create": {"walker": "create_todo", "args": {"title": "<TAG>"}},
  "list":   {"walker": "list_todos"},
  "update": {"walker": "complete_todo", "asserts": {"done": true}},   # optional
  "delete": {"walker": "delete_todo"}                                  # optional
}
Values equal to the sentinel "<TAG>" bind to the unique per-run probe tag.

Usage:  ./behavioral_gate.py candidate.jac manifest.json
Exit 0 = KEEP, 1 = REJECT.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()


def render_value(v) -> str:
    """Render a manifest value as a Jac literal (or the `tag` var for <TAG>)."""
    if v == "<TAG>":
        return "tag"
    if isinstance(v, bool):
        return "True" if v else "False"
    if isinstance(v, (int, float)):
        return str(v)
    if v is None:
        return "None"
    return json.dumps(v)   # strings -> quoted


def _args_str(args: dict | None) -> str:
    if not args:
        return ""
    return ", ".join(f"{k}={render_value(v)}" for k, v in args.items())


def build_probe(manifest: dict, tag: str) -> str:
    node = manifest["node"]
    tf = manifest["tag_field"]
    create = manifest["create"]
    lst = manifest["list"]
    update = manifest.get("update")
    delete = manifest.get("delete")

    L = lst["walker"]
    lines = [
        "with entry {",
        f'    tag = "{tag}";',
        f"    base = len((root spawn {L}()).reports[0]);",
        f"    made = (root spawn {create['walker']}({_args_str(create.get('args'))})).reports[0];",
        f"    after = (root spawn {L}()).reports[0];",
        f"    mine = [n for n in after if n.{tf} == tag];",
        '    assert len(after) - base == 1, "CREATE: no new node reachable from root (hollow create)";',
        '    assert len(mine) == 1, "CREATE: created node not findable by tag";',
    ]
    if update:
        lines.append(f"    made spawn {update['walker']}({_args_str(update.get('args'))});")
        lines.append(
            f"    reread = [n for n in (root spawn {L}()).reports[0] if n.{tf} == tag][0];")
        for k, v in (update.get("asserts") or {}).items():
            lines.append(
                f'    assert reread.{k} == {render_value(v)}, "UPDATE: {k} did not change (no-op update)";')
    if delete:
        lines.append(f"    made spawn {delete['walker']}();")
        lines.append(f"    final = (root spawn {L}()).reports[0];")
        lines.append(
            f'    assert len([n for n in final if n.{tf} == tag]) == 0, "DELETE: node still present (no-op delete)";')
        lines.append('    assert len(final) == base, "DELETE: count did not return to baseline";')
    lines.append('    print("ROUND-TRIP OK");')
    lines.append("}")
    return "\n".join(lines)


def _jac(args: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run([JAC, *args], capture_output=True, text=True, **kw)


def run_gate(candidate_src: str, manifest: dict) -> dict:
    tag = f"{manifest['node']}-probe-{uuid.uuid4().hex[:12]}"
    probe = build_probe(manifest, tag)
    combined = candidate_src.rstrip() + "\n\n" + probe + "\n"

    # Stage 1: type-check the CANDIDATE ALONE (the probe assigns walker reports to
    # `Any`, which the static checker won't let us `spawn` on -- but that resolves at
    # runtime. So the syntactic pre-gate covers only the candidate's own archetypes.)
    cand_path = _write_tmp(candidate_src)
    comb_path = _write_tmp(combined)
    try:
        chk = _jac(["check", cand_path])
        chk_out = chk.stdout + chk.stderr
        if chk.returncode != 0 or "FAILED" in chk_out:
            return {"ok": False, "stage": "check", "tag": tag,
                    "reason": _first_error(chk_out), "output": chk_out}

        # Stage 2: execute candidate+probe; runtime persistence deltas are the gate.
        # (No `-e none`: we want the failing assertion's labelled message to surface.)
        run = _jac(["run", comb_path])
        run_out = run.stdout + run.stderr
        if "ROUND-TRIP OK" in run_out and run.returncode == 0:
            return {"ok": True, "stage": "run", "tag": tag,
                    "reason": "round-trip passed", "output": run_out}
        return {"ok": False, "stage": "run", "tag": tag,
                "reason": _first_error(run_out) or "round-trip did not complete",
                "output": run_out}
    finally:
        os.unlink(cand_path)
        os.unlink(comb_path)


def _write_tmp(src: str) -> str:
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False, encoding="utf-8") as tf:
        tf.write(src)
        return tf.name


def _first_error(out: str) -> str:
    for ln in out.splitlines():
        s = ln.strip()
        if "Error:" in s:                        # "✖ Error: <msg>" (asserts land here)
            return s.split("Error:", 1)[1].strip()
        if "error[" in s:
            return s
    return ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("candidate")
    ap.add_argument("manifest")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()
    with open(args.candidate, encoding="utf-8") as fh:
        src = fh.read()
    with open(args.manifest, encoding="utf-8") as fh:
        manifest = json.load(fh)
    res = run_gate(src, manifest)
    verdict = "KEEP" if res["ok"] else "REJECT"
    print(f"[{verdict}] {res['stage']}: {res['reason']}")
    if args.verbose or not res["ok"]:
        print("--- jac output ---")
        print(res["output"].strip())
    return 0 if res["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
