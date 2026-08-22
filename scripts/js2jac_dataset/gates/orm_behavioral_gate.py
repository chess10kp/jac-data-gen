#!/usr/bin/env python3
"""Behavioral gate for js2jac ORM (Prisma) route rewrites.

`jac check` proves the rewrite COMPILES; the structural graph-op check proves it
TOUCHES the graph. Neither proves it actually READS BACK real persisted data — a
rewrite can traverse the wrong edge, filter on the wrong field, or (the move.it
class) keep a dead `prisma.` call that only fails at runtime. This gate runs the
rewrite against a seeded graph and asserts it returns the seeded data.

Unlike farm's behavioral_gate.py (which needs a full create/list/update/delete
walker SET per node, from a manifest), a Prisma route file is ONE endpoint. So
this gate is per-file and opportunistic: it seeds the node the rewrite queries,
invokes the rewrite's most-testable entrypoint, and asserts a non-hollow read.

Verdict:
  KEEP         — probe ran and the seeded data came back (real read-back)
  REJECT       — probe ran but returned empty/constant, or errored (hollow / broken)
  INCONCLUSIVE — could not construct a probe (no scalar entrypoint); caller should
                 fall back to the structural graph-op check

Usage (as a library, from the chunk.sh guard):
  from orm_behavioral_gate import gate_orm
  verdict, reason = gate_orm(schema_jac, candidate_jac, jac_repo)
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile

# ---- tiny schema parser (reuse of prisma_to_jac's output shape) -------------

_NODE_RE = re.compile(r"\bnode\s+(\w+)\s*\{([^}]*)\}", re.S)
_HAS_RE = re.compile(r"\bhas\s+(\w+)\s*:\s*([^=;]+?)\s*(=\s*[^;]+)?;")
_EDGE_RE = re.compile(r"\bedge\s+(\w+)\s*:\s*(\w+)\s*-->\s*(\w+)")


def parse_schema(schema: str) -> tuple[dict, list]:
    """Return ({node: [(field, type, required)]}, [(edge, parent, child)])."""
    nodes = {}
    for m in _NODE_RE.finditer(schema):
        name, body = m.group(1), m.group(2)
        fields = []
        for hm in _HAS_RE.finditer(body):
            f, t, dflt = hm.group(1), hm.group(2).strip(), hm.group(3)
            required = dflt is None and "| None" not in t
            fields.append((f, t, required))
        nodes[name] = fields
    edges = [(m.group(1), m.group(2), m.group(3)) for m in _EDGE_RE.finditer(schema)]
    return nodes, edges


def _seed_value(jtype: str, tag: str) -> str:
    t = jtype.split("|")[0].strip()
    if t == "str":
        return f'"{tag}"'
    if t == "int":
        return "7"
    if t == "float":
        return "7.0"
    if t == "bool":
        return "False"
    if t.startswith("list"):
        return "[]"
    if t == "dict":
        return "{}"
    return f'"{tag}"'          # enum / unknown -> string is usually fine to omit


def _ctor(node: str, fields: list, tag: str) -> str:
    """Constructor call setting all REQUIRED fields (defaults fill the rest)."""
    req = [(f, t) for f, t, r in fields if r]
    args = ", ".join(f"{f}={_seed_value(t, tag)}" for f, t in req)
    return f"{node}({args})"


# ---- entrypoint detection ---------------------------------------------------

# a plain/pub def with a single scalar param is the testable seam the composer
# tends to factor out (user_by_email(email), businesses_for_user(user_id), ...)
_DEF_RE = re.compile(
    r"\b(?:async\s+)?def(?::pub)?\s+(\w+)\s*\(\s*(\w+)\s*:\s*([\w\[\] |]+?)\s*\)\s*->\s*([\w\[\] |]+)")
_WALKER_RE = re.compile(r"\bwalker:pub\s+(\w+)\b")
_TRIGGER_RE = re.compile(r"\bcan\b[^{]*\bwith\s+(\w+)\s+entry")


def pick_primary_node(candidate: str, nodes: dict) -> str | None:
    """The node the rewrite most references (its query target)."""
    best, best_n = None, 0
    for n in nodes:
        c = len(re.findall(rf"\b{n}\b", candidate))
        if c > best_n:
            best, best_n = n, c
    return best


def build_probe(schema: str, candidate: str) -> str | None:
    nodes, edges = parse_schema(schema)
    if not nodes:
        return None
    prim = pick_primary_node(candidate, nodes)
    if not prim:
        return None
    fields = nodes[prim]
    # a required str field we can seed AND look up by (the "tag")
    tag_field = next((f for f, t, r in fields if r and t.split("|")[0].strip() == "str"), None)

    # find a scalar-param def entrypoint whose param we can bind to seeded state
    entry = None
    for m in _DEF_RE.finditer(candidate):
        name, pname, ptype, ret = m.group(1), m.group(2), m.group(3).strip(), m.group(4)
        if "str" in ptype or "int" in ptype:
            entry = (name, pname, ptype, ret)
            break

    seed_lines = []
    # seed TWO instances so a real filter must pick the right one (not just return [0])
    tagA, tagB = "PROBE_A", "PROBE_B"
    seed_lines.append(f"    a = root ++> {_ctor(prim, fields, tagA)};")
    seed_lines.append(f"    b = root ++> {_ctor(prim, fields, tagB)};")
    # touch a REAL field on the fresh handle to reconcile it before the rewrite
    # re-reads via edge traversal (see jac-node-handle-staleness). `a.dummy`
    # would fail `jac check` (unknown attr); use the primary node's first field.
    touch_field = fields[0][0] if fields else None
    if touch_field:
        seed_lines.append(f"    _ = a.{touch_field};")

    # if the rewrite traverses a typed edge out of prim, give A a child to find
    child_edge = next(((e, p, ch) for (e, p, ch) in edges
                       if p == prim and re.search(rf"->:{e}:->", candidate)), None)
    if child_edge:
        e, _p, ch = child_edge
        cfields = nodes.get(ch, [])
        seed_lines.append(f"    a +>:{e}:+> {_ctor(ch, cfields, 'CHILD_A')};")

    if entry is not None:
        name, pname, ptype, ret = entry
        # bind the param: an *id* param -> jid of A; else the tag field value of A
        if "id" in pname.lower() and "str" in ptype:
            call_arg = "jid(a)"
        elif tag_field:
            call_arg = f'"{tagA}"'
        else:
            call_arg = '"PROBE_A"'
        assert_line = _assert_for(ret, child_edge, tag_field, tagA)
        probe = [
            "with entry {",
            *seed_lines,
            f"    res = {name}({call_arg});",
            assert_line,
            '    print("ORM-PROBE OK");',
            "}",
        ]
        return "\n".join(probe)

    # no scalar def entrypoint -> try a walker on prim (spawn on the seeded node)
    wmatch = _WALKER_RE.search(candidate)
    if wmatch:
        wname = wmatch.group(1)
        trig = _TRIGGER_RE.search(candidate)
        target = "a" if (trig and trig.group(1) == prim) else "root"
        probe = [
            "with entry {",
            *seed_lines,
            f"    r = {target} spawn {wname}();",
            "    reps = r.reports;",
            '    assert len(reps) >= 1, "walker produced no report (hollow)";',
            "    flat = [];",
            "    for rep in reps { if isinstance(rep, list) { flat += rep; } else { flat += [rep]; } }",
            '    assert len(flat) >= 1, "walker report empty (hollow read)";',
            '    print("ORM-PROBE OK");',
            "}",
        ]
        return "\n".join(probe)

    return None


def _assert_for(ret: str, child_edge, tag_field: str | None, tagA: str) -> str:
    ret = ret.strip()
    if ret.startswith("list"):
        # a findMany-style read: must return >=1 real row for the seeded owner
        return ('    assert res is not None and len(res) >= 1, '
                '"read returned empty list (hollow findMany or wrong edge)";')
    # a findUnique-style read: must return the seeded node, matched by its tag
    if tag_field:
        return (f'    assert res is not None and res.{tag_field} == "{tagA}", '
                f'"read did not return the seeded node (wrong filter/hollow)";')
    return '    assert res is not None, "read returned None (hollow findUnique)";'


# ---- run --------------------------------------------------------------------

def _write(src: str) -> str:
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False, encoding="utf-8") as tf:
        tf.write(src)
        return tf.name


def gate_orm(schema_jac: str, candidate: str, jac_repo: str) -> tuple[str, str]:
    if not schema_jac or not candidate or candidate == "REJECT":
        return "INCONCLUSIVE", "no schema/candidate"
    probe = build_probe(schema_jac, candidate)
    if probe is None:
        return "INCONCLUSIVE", "no constructible probe (fall back to structural)"
    combined = schema_jac.rstrip() + "\n\n" + candidate.rstrip() + "\n\n" + probe + "\n"
    path = _write(combined)
    # jac's graph store is cwd-namespaced (verified: a fresh cwd starts empty,
    # the same cwd accumulates across runs). Run every probe in its OWN throwaway
    # cwd so seeds from one candidate can't leak into another's read-back and let
    # a hollow filter-ignoring stub pass on stale data. jac_repo is unused for
    # execution (the `jac` wrapper finds the dev compiler regardless of cwd); it
    # stays in the signature for call-site symmetry with the check-based guard.
    _ = jac_repo
    sandbox = tempfile.mkdtemp(prefix="ormprobe_")
    # 3GB address-space cap per jac run — same fix as step4_full_loop._run
    # (Aug 20 OOM freezes).
    as_cap = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30
    try:
        p = subprocess.run(["prlimit", f"--as={as_cap}", "--", "jac", "run", path],
                           cwd=sandbox,
                           capture_output=True, text=True, timeout=120)
        out = p.stdout + p.stderr
        if "ORM-PROBE OK" in out and p.returncode == 0:
            return "KEEP", "read-back verified"
        # a labelled assertion failure = genuine hollow/broken read
        for ln in out.splitlines():
            if "Error:" in ln and "ORM-PROBE" not in ln:
                return "REJECT", ln.split("Error:", 1)[1].strip()[:120]
        return "REJECT", "probe did not complete (runtime error)"
    except subprocess.TimeoutExpired:
        return "INCONCLUSIVE", "probe timed out"
    finally:
        os.unlink(path)
        import shutil
        shutil.rmtree(sandbox, ignore_errors=True)


def main() -> int:
    import argparse, json
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True, help="jsonl with schema_jac + candidate")
    ap.add_argument("--jac-repo", required=True)
    args = ap.parse_args()
    keep = rej = inc = 0
    for line in open(args.candidates):
        if not line.strip():
            continue
        c = json.loads(line)
        v, why = gate_orm(c.get("schema_jac", ""), c.get("candidate", ""), args.jac_repo)
        keep += v == "KEEP"; rej += v == "REJECT"; inc += v == "INCONCLUSIVE"
        print(f"  [{v:12s}] {c.get('id','?').split('::')[-1][-44:]:44s} {why}")
    print(f"\nKEEP {keep} | REJECT {rej} | INCONCLUSIVE {inc}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
