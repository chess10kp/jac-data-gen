#!/usr/bin/env python3
"""Mutant generation + application for the `testgen` agent-task kind.

A testgen task hands the agent WORKING Jac code and asks for a test suite. The
hidden grader is a frozen mutant set: the agent's tests must pass on the
original and fail ("kill") >= threshold of the mutants.

Mutant record (one JSON object per line in grader/mutants*.jsonl):
    {"id": "m07", "source": "mechanical"|"hand"|"native-negative",
     "op": "cmp >=->>", "why": "...",
     "edits": [{"file": "apiary.jac", "offset": 612, "old": ">=", "new": ">"}]}
Edits carry an absolute offset AND the expected old text, so a mutant can never
silently apply to the wrong site (apply_mutant raises on mismatch).

Operators extend scripts/lib/step4_mutation.py (arith/compare/bool swaps,
int-literal +1, condition negation, not-in/in, min/max/sorted swaps, method
swaps) with Jac/OSP-specific ones: edge-direction flips (`-->` <-> `<--`,
`++>` -> `<++`), and statement deletion of `visit` / `report` / `disengage` /
`break` / `continue` / augmented assignment / bare call statements.
int<->float swap is deliberately NOT an operator (equivalent under ==, see
memory mutation-gate.md).

Only code inside the task's scope regions is mutated (a region = the brace
block of a named archetype/ability/def, or the whole file). Strings, comments,
imports, type annotations and the `->` return arrow are never mutated.
"""
from __future__ import annotations

import json
import random
import re
from pathlib import Path

# ---------------------------------------------------------------- masking --
_STR_RE = re.compile(
    r'(?:[rRbBfF]{0,2})(?:"""(?:.|\n)*?"""|\'\'\'(?:.|\n)*?\'\'\'|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\')')
_BLOCK_COMMENT_RE = re.compile(r"#\*(?:.|\n)*?\*#")
_LINE_COMMENT_RE = re.compile(r"#[^\n]*")


def mask(src: str) -> str:
    """Same-length copy of src with strings/comments blanked (newlines kept)."""
    def blank(m: re.Match) -> str:
        return "".join("\n" if c == "\n" else " " for c in m.group(0))
    out = _BLOCK_COMMENT_RE.sub(blank, src)
    # strings before line comments ("#" inside a string is not a comment)
    out = _STR_RE.sub(blank, out)
    out = _LINE_COMMENT_RE.sub(blank, out)
    return out


def _match_close(masked: str, open_idx: int, o: str = "{", c: str = "}") -> int | None:
    depth = 0
    for i in range(open_idx, len(masked)):
        if masked[i] == o:
            depth += 1
        elif masked[i] == c:
            depth -= 1
            if depth == 0:
                return i
    return None


def find_region(src: str, header: str) -> tuple[int, int]:
    """(start, end) of the brace block whose header line contains `header`
    (e.g. "walker RequeenAudit", "def add_hive", "can finish with"). The region
    spans from the header to its closing brace."""
    masked = mask(src)
    pat = re.compile(r"(?m)^[ \t]*(?:[\w:]+\s+)*" + re.escape(header) + r"\b")
    m = pat.search(masked)
    if not m:
        raise ValueError(f"scope header not found: {header!r}")
    ob = masked.find("{", m.end())
    cb = _match_close(masked, ob)
    if ob < 0 or cb is None:
        raise ValueError(f"no brace block after {header!r}")
    return m.start(), cb + 1


# --------------------------------------------------------------- operators --
_EDGE_MASK = re.compile(r"\|>|<\||<-->|<\+\+>|-->|<--|\+\+>|<\+\+|->:|:->|<-:|:<-|\+>:|:\+>|<\+:|:<\+|->|\*\*|//")
_OP_RE = re.compile(r"(<=|>=|==|!=|\band\b|\bor\b|\bTrue\b|\bFalse\b|<|>|-|\+|\*|/|%)")
_OP_SWAP = {
    "<=": "<", ">=": ">", "==": "!=", "!=": "==", "<": "<=", ">": ">=",
    "+": "-", "-": "+", "*": "/", "/": "*", "%": "*",
    "and": "or", "or": "and", "True": "False", "False": "True",
}
_INT_RE = re.compile(r"(?<![\w.])(\d+)(?![\w.])")
_COND_RE = re.compile(r"\b(if|elif|while)\s+")
_NOTIN_RE = re.compile(r"\bnot\s+in\b")
_IN_RE = re.compile(r"(?<!not )\bin\b")
_NOT_RE = re.compile(r"\bnot\s+(?!in\b)")
_CALL_RE = re.compile(r"(?<![\w.])(min|max|sorted|any|all)\s*\(")
_CALL_SWAP = {"min": "max", "max": "min", "sorted": "list", "any": "all", "all": "any"}
_METH_RE = re.compile(r"\.(lower|upper|startswith|endswith|append|strip|lstrip|rstrip)\s*\(")
_METH_SWAP = {"lower": "upper", "upper": "lower", "startswith": "endswith",
              "endswith": "startswith", "strip": "lstrip", "lstrip": "rstrip", "rstrip": "lstrip"}
_STMT_DEL_RE = re.compile(
    r"(?m)^([ \t]*)((?:report|visit|disengage|break|continue|skip)\b[^\n;{}]*;"
    r"|[\w.\[\]]+\s*(?:\+=|-=|\*=|/=)[^\n;{}]*;"
    r"|[\w.]+\.(?:append|extend|insert|remove|pop|add|discard|update|sort)\([^\n;]*\)\s*;"
    r"|del\s+[^\n;]*;)[ \t]*$")


def _skip_line(masked: str, i: int) -> bool:
    ls = masked.rfind("\n", 0, i) + 1
    le = masked.find("\n", i)
    line = masked[ls:le if le >= 0 else len(masked)].strip()
    return line.startswith(("import ", "include ", "from ", "@"))


def _in_annotation(masked: str, i: int) -> bool:
    """True if offset i sits in a type annotation (`x: T`, `-> T`)."""
    ls = masked.rfind("\n", 0, i) + 1
    pre = masked[ls:i]
    # after `->` up to the opening `{` on the same line
    if "->" in pre and "{" not in pre[pre.rfind("->"):]:
        return True
    # `name: type` declaration up to `=` / `,` / `)` / `;`
    m = list(re.finditer(r"\b\w+\s*:\s*(?!:)", pre))
    if m:
        tail = pre[m[-1].end():]
        if not re.search(r"[=,);{]", tail) and not re.search(r"\?:", pre[m[-1].start() - 2:m[-1].end()]):
            return True
    return False


def generate(src: str, file: str, regions: list[tuple[int, int]] | None = None) -> list[dict]:
    """All single-point mechanical mutants of `src` within `regions`."""
    masked = mask(src)
    if not regions:
        regions = [(0, len(src))]
    edge_masked = _EDGE_MASK.sub(lambda m: " " * len(m.group(0)), masked)
    out: list[dict] = []
    seen: set[tuple[int, str, str]] = set()

    def inside(i: int) -> bool:
        return any(a <= i < b for a, b in regions)

    def add(start: int, end: int, new: str, op: str) -> None:
        if not inside(start) or _skip_line(masked, start):
            return
        old = src[start:end]
        if old == new or (start, old, new) in seen:
            return
        seen.add((start, old, new))
        line = src.count("\n", 0, start) + 1
        out.append({"source": "mechanical", "op": op, "line": line,
                    "edits": [{"file": file, "offset": start, "old": old, "new": new}]})

    for m in _OP_RE.finditer(edge_masked):
        tok = m.group(0)
        if _in_annotation(masked, m.start()):
            continue
        if tok in "+-" and m.start() + 1 < len(masked) and masked[m.start() + 1] == "=" and tok + "=" == masked[m.start():m.start() + 2]:
            add(m.start(), m.start() + 1, _OP_SWAP[tok], f"aug {tok}=->{_OP_SWAP[tok]}=")
            continue
        if tok in ("<", ">") and masked[m.start() + 1:m.start() + 2] == "=":
            continue  # part of <= / >= handled as its own token
        if tok == "=" or tok not in _OP_SWAP:
            continue
        if tok in ("*", "/") and masked[m.start() + 1:m.start() + 2] == "=":
            add(m.start(), m.start() + 1, _OP_SWAP[tok], f"aug {tok}=->{_OP_SWAP[tok]}=")
            continue
        if tok == "-":
            pre = masked[:m.start()].rstrip()
            if not pre or not (pre[-1].isalnum() or pre[-1] in ")]_"):
                # unary minus: drop it
                add(m.start(), m.end(), "", "neg-drop")
                continue
        if tok in ("<", ">"):
            cat = "cmp"
        elif tok in ("and", "or"):
            cat = "bool"
        elif tok in ("True", "False"):
            cat = "const"
        elif tok in ("==", "!=", "<=", ">="):
            cat = "cmp"
        else:
            cat = "arith"
        add(m.start(), m.end(), _OP_SWAP[tok], f"{cat} {tok}->{_OP_SWAP[tok]}")
    for m in re.finditer(r"//", masked):
        if not _in_annotation(masked, m.start()):
            add(m.start(), m.end(), "/", "arith //->/")
    for m in re.finditer(r"\*\*", masked):
        add(m.start(), m.end(), "*", "arith **->*")

    for m in _INT_RE.finditer(masked):
        if _in_annotation(masked, m.start()):
            continue
        v = int(m.group(1))
        add(m.start(), m.end(), str(v + 1), f"int {v}->{v + 1}")
        if v > 0:
            add(m.start(), m.end(), str(v - 1), f"int {v}->{v - 1}")

    for m in _COND_RE.finditer(masked):
        cs = m.end()
        ob = masked.find("{", cs)
        if ob < 0:
            continue
        cond = src[cs:ob].rstrip()
        if not cond.strip():
            continue
        add(cs, cs + len(cond), f"not ({cond})", f"negate {m.group(1)}")

    for m in _NOTIN_RE.finditer(masked):
        add(m.start(), m.end(), "in", "not-in->in")
    for m in _NOT_RE.finditer(masked):
        add(m.start(), m.end(), "", "not-drop")

    for m in re.finditer(r"(?<![<+])-->", masked):
        add(m.start(), m.end(), "<--", "edge -->-><--")
    for m in re.finditer(r"<--(?!>)", masked):
        add(m.start(), m.end(), "-->", "edge <---->")
    for m in re.finditer(r"(?<!<)\+\+>", masked):
        add(m.start(), m.end(), "<++", "connect ++>-><++")

    for m in _CALL_RE.finditer(masked):
        name = m.group(1)
        add(m.start(1), m.end(1), _CALL_SWAP[name], f"call {name}->{_CALL_SWAP[name]}")
    for m in _METH_RE.finditer(masked):
        name = m.group(1)
        if name in _METH_SWAP:
            add(m.start(1), m.end(1), _METH_SWAP[name], f"meth {name}->{_METH_SWAP[name]}")
    for m in re.finditer(r"\breverse\s*=\s*(True|False)\b", masked):
        v = m.group(1)
        add(m.start(1), m.end(1), "False" if v == "True" else "True", "sort-reverse flip")

    for m in _STMT_DEL_RE.finditer(masked):
        s, e = m.start(2), m.end(2)
        kw = masked[s:e].split()[0].rstrip(";")
        add(s, e, "", f"stmt-del {kw[:24]}")
    return out


def sample(muts: list[dict], cap: int, seed: str) -> list[dict]:
    """Deterministic, operator-stratified sample of at most `cap` mutants."""
    if len(muts) <= cap:
        return list(muts)
    rng = random.Random(seed)
    by: dict[str, list[dict]] = {}
    for m in muts:
        by.setdefault(m["op"].split()[0], []).append(m)
    for v in by.values():
        rng.shuffle(v)
    picked: list[dict] = []
    keys = sorted(by)
    while len(picked) < cap:
        progressed = False
        for k in keys:
            if by[k] and len(picked) < cap:
                picked.append(by[k].pop())
                progressed = True
        if not progressed:
            break
    picked.sort(key=lambda m: (m["edits"][0]["file"], m["edits"][0]["offset"]))
    return picked


def anchor_to_offsets(ws: Path, edits: list[dict]) -> list[dict]:
    """Convert {"file","old","new"} anchor edits (unique anchor) to offset edits."""
    out = []
    for ed in edits:
        src = (ws / ed["file"]).read_text()
        n = src.count(ed["old"])
        if n != 1:
            raise ValueError(f"anchor occurs {n}x in {ed['file']}: {ed['old'][:60]!r}")
        out.append({"file": ed["file"], "offset": src.index(ed["old"]), "old": ed["old"], "new": ed["new"]})
    return out


def apply_mutant(ws: Path, mut: dict) -> None:
    """Apply a mutant's edits in place inside workspace ws."""
    by: dict[str, list[dict]] = {}
    for ed in mut["edits"]:
        by.setdefault(ed["file"], []).append(ed)
    for f, eds in by.items():
        p = ws / f
        src = p.read_text()
        for ed in sorted(eds, key=lambda e: -e["offset"]):
            o = ed["offset"]
            if src[o:o + len(ed["old"])] != ed["old"]:
                raise ValueError(f"mutant {mut.get('id')}: stale edit at {f}:{o} (expected {ed['old']!r})")
            src = src[:o] + ed["new"] + src[o + len(ed["old"]):]
        p.write_text(src)


def load_jsonl(p: Path) -> list[dict]:
    return [json.loads(l) for l in p.read_text().splitlines() if l.strip()] if p.exists() else []
