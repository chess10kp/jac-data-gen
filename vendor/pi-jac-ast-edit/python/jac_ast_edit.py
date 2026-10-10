#!/usr/bin/env python3
"""jac_ast_edit — AST-native surgical editor for Jac, backed by tree-sitter.

Protocol (JSON over stdin/stdout):
    jac_ast_edit.py symbols <file>
    jac_ast_edit.py search  <root>     # body: {"query": "...", "kind": "...", "mode": "symbols"}
    jac_ast_edit.py edit    <file>     # body: {"operations": [ ... ]}

Edits by symbol, not string: {action, target, name} locates a symbol through
the tree-sitter parse tree, computes byte spans, and splices text. Batches are
atomic — all ops resolve against the ORIGINAL tree, splices apply in one pass,
and the result is re-parsed; if the new source has more ERROR nodes than the
original, the batch is rejected and nothing is written.
"""
from __future__ import annotations

import fnmatch
import hashlib
import json
import os
import re
import sys
from pathlib import Path

from tree_sitter import Node, Tree

from tree_sitter_jac import new_parser

import edit_view
import jac_check

# --------------------------------------------------------------------------
# helpers


class EditError(Exception):
    def __init__(self, code: str, message: str, suggestions=None):
        super().__init__(message)
        self.code = code
        self.message = message
        self.suggestions = suggestions or []


def _named(n: Node) -> Node:
    """Unwrap container nodes (element / archetype_member wrappers)."""
    while n and n.type in ("element", "archetype_member") and n.named_child_count:
        n = n.named_children[0]
    return n


def _field(n: Node | None, name: str) -> Node | None:
    return n.child_by_field_name(name) if n else None


def _node_text(n: Node) -> str:
    return n.text.decode("utf-8", "replace")


def _edit_distance(a: str, b: str) -> int:
    """Damerau-Levenshtein-ish distance — small, good enough for did-you-mean."""
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i in range(1, len(a) + 1):
        curr = [i]
        for j in range(1, len(b) + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            curr.append(min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost))
        prev = curr
    return prev[-1]


def _closest_symbol_name(needle: str, qualified_names: list[str]) -> str | None:
    """Case-insensitive fuzzy match; strips dot prefixes so 'greet' matches
    'Card.greet'. Returns None when nothing is within threshold."""
    if not needle or not qualified_names:
        return None
    # Match the full needle and its last dotted segment ("Card.labl" → "labl").
    targets = [needle.lower()]
    last = needle.split(".")[-1].lower()
    if last != targets[0]:
        targets.append(last)
    threshold = max(2, (len(needle) * 2 + 4) // 5)  # ceil(0.4 * len)
    best: tuple[str, int] | None = None
    for name in qualified_names:
        bare = name.split(".")[-1]
        d = min(_edit_distance(t, bare.lower()) for t in targets)
        if d <= threshold and (best is None or d < best[1]):
            best = (name, d)
    return best[0] if best else None


def _count_errors(root: Node) -> int:
    count = 0
    stack = [root]
    while stack:
        n = stack.pop()
        if n.type == "ERROR" or n.is_missing:
            count += 1
        stack.extend(n.children)
    return count


# --------------------------------------------------------------------------
# symbol index


def _kind_of_archetype(n: Node) -> str:
    k = _field(n, "kind")
    return _node_text(k) if k else "archetype"


def _test_label(n: Node) -> str | None:
    """test foo { } — grammar currently leaves the name as a bare token/ERROR.
    Recover it: first non-'test' child before '{' that has word text."""
    for ch in n.children:
        if ch.type == "{" or ch.type == "block_body":
            break
        if ch.type == "test":
            continue
        txt = _node_text(ch).strip()
        if txt and txt != "test":
            return txt
    return None


class Symbol:
    __slots__ = ("kind", "name", "qualified", "node", "parent", "index")

    def __init__(self, kind, name, qualified, node, parent=None, index=0):
        self.kind = kind
        self.name = name
        self.qualified = qualified
        self.node = node
        self.parent = parent
        self.index = index


def _index_symbols(root: Node) -> list[Symbol]:
    symbols: list[Symbol] = []
    counters: dict[str, int] = {}

    def add(kind, name, node, parent=None):
        qualified = f"{parent}.{name}" if parent and name else (name or "")
        key = (parent or "") + "\x00" + kind + "\x00" + (name or "")
        idx = counters.get(key, 0)
        counters[key] = idx + 1
        symbols.append(Symbol(kind, name, qualified, node, parent, idx))

    def walk_members(owner: Node, owner_name: str):
        for member in owner.named_children:
            m = _named(member)
            if m.type == "ability":
                nm = _field(m, "name")
                add("ability", _node_text(nm) if nm else None, m, owner_name)
            elif m.type == "has_statement":
                for hv in m.named_children:
                    if hv.type == "has_var":
                        nm = _field(hv, "name")
                        add("has", _node_text(nm) if nm else None, hv, owner_name)
            elif m.type == "test":
                label = _test_label(m)
                add("test", label, m, owner_name)
            elif m.type == "archetype_member":
                walk_members(m, owner_name)  # nested wrapper forms

    def walk_enum(enu: Node, ename: str):
        for ch in enu.named_children:
            if ch.type == "enum_member":
                nm = _node_text(ch).split("=")[0].strip()
                add("member", nm, ch, ename)

    for top in root.named_children:
        real = _named(top)
        t = real.type
        if t == "archetype":
            kind = _kind_of_archetype(real)
            nm = _field(real, "name")
            name = _node_text(nm) if nm else None
            add(kind, name, real)
            for ch in real.named_children:
                if ch.type in ("archetype_member", "accessor_block"):
                    walk_members(ch, name)
        elif t == "ability":
            nm = _field(real, "name")
            name = _node_text(nm) if nm else None
            add("function", name, real)
        elif t == "enum":
            nm = _field(real, "name")
            name = _node_text(nm) if nm else None
            add("enum", name, real)
            walk_enum(real, name)
        elif t == "global_var":
            nm = _field(real, "name")
            add("glob", _node_text(nm) if nm else None, real)
        elif t == "impl":
            tgt = _field(real, "target")
            add("impl", _node_text(tgt) if tgt else None, real)
        elif t == "test":
            add("test", _test_label(real), real)
        elif t == "type_alias":
            nm = _field(real, "name")
            add("type", _node_text(nm) if nm else None, real)
        elif t == "import_statement":
            add("import", None, real)
        elif t == "module_code":
            add("code", None, real)
    return symbols


ARCHETYPE_KINDS = ("obj", "node", "edge", "walker", "class")

# Each symbol is indexed ONCE under its canonical kind (obj/node/edge/walker/
# class, function = module-level def/can, ability = member def/can, has, impl,
# enum, member, glob, type, test, import, code). Synonyms only widen matching:
# - search `kind` filter (strict): archetype → any archetype kind,
#   method → ability, property → has.
# - edit `target` (lenient): any archetype kind matches any archetype (the
#   name already pins the symbol), and function/ability/method match module
#   defs, member abilities AND impl blocks — ambiguity is resolved in _resolve.
KIND_SYNONYMS = {
    "archetype": set(ARCHETYPE_KINDS),
    "method": {"ability"},
    "property": {"has"},
}
TARGET_FAMILIES = {
    **{k: set(ARCHETYPE_KINDS) for k in ARCHETYPE_KINDS + ("archetype",)},
    **{k: {"function", "ability", "impl"} for k in ("function", "ability", "method")},
    "property": {"has"},
}


def _kind_matches(want: str, kind: str) -> bool:
    want = want.lower()
    return kind == want or kind in KIND_SYNONYMS.get(want, ())


def _sym_label(s: Symbol) -> str:
    line = s.node.start_point[0] + 1
    return f"{s.kind} {s.qualified or s.kind} (line {line})"


def _resolve(symbols: list[Symbol], target: str | None, name: str | None,
             index: int | None, require=True, needs_body=False) -> Symbol:
    target = (target or "").lower()
    name = name or None
    kinds = TARGET_FAMILIES.get(target, {target})
    cands = [s for s in symbols if (not target or s.kind in kinds)]
    if name:
        cands = [s for s in cands if s.name == name or s.qualified == name]
    if index is None and len(cands) > 1:
        # Several symbols fit. Narrow by what the op needs: body ops want the
        # one with a braced body (an impl over its bodyless declaration);
        # other ops prefer declarations over impl blocks.
        if needs_body:
            narrowed = [s for s in cands if _brace_span(s.node) is not None]
        else:
            narrowed = [s for s in cands if s.kind != "impl"]
        if len(narrowed) == 1:
            return narrowed[0]
        if require:
            listing = [f"index={i}: {_sym_label(s)}" for i, s in enumerate(cands)]
            raise EditError(
                "ambiguous_symbol",
                f"{len(cands)} symbols match target={target!r} name={name!r}; "
                "pass a more specific target/name, or index",
                listing[:20])
    idx = index or 0
    if idx >= len(cands) or idx < 0:
        if not require:
            return None
        hints = []
        if name:
            same = [s for s in symbols if s.name == name or s.qualified == name]
            if same:
                hints.append("exists as: " + "; ".join(
                    f"{_sym_label(s)} -> use target={s.kind!r}" for s in same[:5]))
            else:
                names = [s.qualified or s.name or "" for s in symbols]
                close = _closest_symbol_name(name, names)
                if close:
                    hints.append(f'Did you mean: "{close}"?')
        pool = sorted({f"{s.kind}:{s.qualified or s.kind}" for s in symbols
                       if s.kind != "import"})
        shown = ", ".join(pool[:40]) or "<empty file>"
        more = f" (+{len(pool) - 40} more; list them with jac_ast_search mode='outline' root=<file>)" if len(pool) > 40 else ""
        hints.append(f"available: {shown}{more}")
        raise EditError("symbol_not_found",
                        f"no symbol target={target!r} name={name!r} index={idx}",
                        hints)
    return cands[idx]


def _import_info(stmt: Node) -> dict:
    """(path, items, is_from) for an import_statement node."""
    path_txt = None
    items: list[str] = []
    is_from = False
    for c in stmt.children:
        if c.type == "import_path":
            path_txt = _node_text(c)
        elif c.type == "import_items":
            is_from = True
            items = [_node_text(ic) for ic in c.named_children]
    return {"path": path_txt, "items": items, "is_from": is_from}


# --------------------------------------------------------------------------
# span computation


def _brace_span(n: Node) -> tuple[Node, Node] | None:
    """(open, close) brace tokens of n's body. The grammar puts '{' / '}' as
    DIRECT children of ability/impl/archetype/enum/test/module_code (block_body
    holds only the statements), so this also covers empty `{}` bodies."""
    opens = [c for c in n.children if c.type == "{"]
    closes = [c for c in n.children if c.type == "}"]
    if not opens or not closes or closes[-1].start_byte < opens[0].end_byte:
        return None
    return opens[0], closes[-1]


def _line_indent(src: bytes, pos: int) -> str:
    """Leading whitespace of the line containing byte offset pos."""
    ls = src.rfind(b"\n", 0, pos) + 1
    le = ls
    while le < len(src) and src[le] in (32, 9):
        le += 1
    return src[ls:le].decode("utf-8", "replace")


def _detect_indent(src: bytes) -> str:
    """The file's indent unit: a tab if lines are tab-indented, else the
    smallest positive run of leading spaces (default four)."""
    widths = []
    for line in src.split(b"\n"):
        stripped = line.lstrip(b" \t")
        if stripped != line and stripped:
            lead = line[: len(line) - len(stripped)]
            if lead.startswith(b"\t"):
                return "\t"
            widths.append(len(lead))
    return " " * min(widths) if widths else "    "


def _reindent(code: str, base: str) -> str:
    """Re-anchor a multi-line snippet at `base` indentation.

    Accepts relative style (lines indented relative to the snippet) and
    absolute style (continuation lines already at final file indentation,
    first line bare): the least-indented non-empty line — ignoring a bare
    first line — lands at `base`, other lines keep their offset from it."""
    lines = code.strip("\n").split("\n")
    if not any(ln.strip() for ln in lines):
        return ""

    def width(ln: str) -> int:
        return len(ln[: len(ln) - len(ln.lstrip())].replace("\t", "    "))

    cont = [width(ln) for ln in lines[1:] if ln.strip()]
    first_w = width(lines[0])
    if first_w > 0 or not cont:
        m = min([first_w] + cont)
    else:
        m = min(cont)
    out = []
    for i, ln in enumerate(lines):
        if not ln.strip():
            out.append("")
            continue
        extra = 0 if (i == 0 and first_w == 0) else max(0, width(ln) - m)
        out.append(base + " " * extra + ln.lstrip())
    return "\n".join(out)


def _trim_removal(src: bytes, start: int, end: int) -> tuple[int, int]:
    """Expand a removal to full line(s) and eat resulting blank lines."""
    ls = src.rfind(b"\n", 0, start) + 1
    le = src.find(b"\n", end)
    le = len(src) if le == -1 else le + 1
    if src[ls:end].strip() == b"":
        pass  # whole-line node already
    if le < len(src) and src[le:].lstrip(b" \t").startswith(b"\n") is False:
        pass
    # eat following blank lines
    while le < len(src) and src[le] in (32, 9):
        nxt = src.find(b"\n", le)
        nxt = len(src) if nxt == -1 else nxt
        if src[le:nxt].strip() == b"" and nxt > le:
            le = nxt + 1
        else:
            break
    # if previous line is blank and next line is blank or EOF, eat one blank above
    prev_end = ls - 1  # at the '\n' ending previous line
    above_ls = src.rfind(b"\n", 0, prev_end) + 1
    if above_ls <= prev_end and src[above_ls:prev_end].strip() == b"":
        below = src[le:le + 80]
        # ... also when the removed member was the last one before a closing brace
        if (below.strip() == b"" or le >= len(src) or below.lstrip().startswith(b"\n")
                or below.lstrip(b" \t").startswith(b"}")):
            ls = above_ls
    return ls, le


def _find_anchor(text: str, anchor: str, start: int = 0) -> list[tuple[int, int]]:
    """(start, end) char spans of anchor in text[start:]. Exact match first;
    if that finds nothing, retry whitespace-insensitively (runs of whitespace
    in the anchor match any whitespace run), so a wrong indentation or line
    break inside an anchor still locates the code."""
    hits = []
    i = text.find(anchor, start)
    while anchor and i != -1:
        hits.append((i, i + len(anchor)))
        i = text.find(anchor, i + 1)
    if hits or not anchor.strip():
        return hits
    pat = re.compile(r"\s+".join(re.escape(t) for t in anchor.split()))
    return [(m.start(), m.end()) for m in pat.finditer(text, start)]


# --------------------------------------------------------------------------
# operations


_FROM_IMPORT_RE = re.compile(r"^\s*import\s+from\s+([\w.]+)\s*\{([^}]*)\}\s*;?\s*$")
# `count: int = 5` / `name = 1` (a bare field) vs a member declaration.
_FIELD_RE = re.compile(r"^[A-Za-z_]\w*\s*[:=]")
_MEMBER_DECL_RE = re.compile(
    r"^(@|def\b|can\b|async\b|static\b|override\b|impl\b|test\b|"
    r"obj\b|node\b|edge\b|walker\b|class\b|enum\b)")


class Engine:
    def __init__(self, src: bytes, tree: Tree):
        self.src = src
        self.tree = tree
        self.symbols = _index_symbols(tree.root_node)
        self.splices: list[tuple[int, int, bytes, str]] = []  # start, end, repl, label

    def splice(self, start: int, end: int, repl: str | bytes, label: str):
        self.splices.append((start, end, repl.encode() if isinstance(repl, str) else repl, label))

    # -- locate helpers ----------------------------------------------------

    def must(self, target, name, index, needs_body=False) -> Symbol:
        return _resolve(self.symbols, target, name, index, needs_body=needs_body)

    # -- micro ops ---------------------------------------------------------

    def op_rename(self, op):
        s = self.must(op.get("target"), op.get("name"), op.get("index"))
        nm = _field(s.node, "name")
        if nm is None:
            raise EditError("no_name_node", f"symbol {s.qualified or s.kind} has no name node; use replace")
        self.splice(nm.start_byte, nm.end_byte, op["value"], f"rename {s.qualified}")

    def op_remove(self, op):
        s = self.must(op.get("target"), op.get("name"), op.get("index"))
        ls, le = _trim_removal(self.src, s.node.start_byte, s.node.end_byte)
        self.splice(ls, le, "", f"remove {s.qualified or s.kind}")

    def op_set_initializer(self, op):
        s = self.must(op.get("target") or "has", op.get("name"), op.get("index"))
        node = s.node
        eq = next((c for c in node.children if c.type == "="), None)
        if eq:
            # value expression runs from after '=' to end (before ';')
            semi = next((c for c in node.children if c.type == ";"), None)
            vstart = eq.end_byte
            vend = semi.start_byte if semi else node.end_byte
            while vend > vstart and chr(self.src[vend - 1]).isspace():
                vend -= 1
            while vstart < vend and chr(self.src[vstart]).isspace():
                vstart += 1
            self.splice(vstart, vend, op["value"], f"set_initializer {s.qualified}")
        else:
            semi = next((c for c in node.children if c.type == ";"), None)
            pos = semi.start_byte if semi else node.end_byte
            self.splice(pos, pos, f" = {op['value']}", f"add_initializer {s.qualified}")

    def op_set_return_type(self, op):
        s = self.must(op.get("target") or "function", op.get("name"), op.get("index"))
        sig = next((c for c in s.node.named_children if c.type == "func_signature"), None)
        rt = _field(sig, "return_type") if sig else None
        val = op["value"]
        if rt is not None:
            self.splice(rt.start_byte, rt.end_byte, val, f"set_return_type {s.qualified}")
            return
        if sig is None:
            raise EditError("no_signature", f"{s.qualified} has no func_signature")
        arrow = next((c for c in sig.children if c.type == "->"), None)
        if arrow:
            self.splice(arrow.end_byte, arrow.end_byte, f" {val}", f"set_return_type {s.qualified}")
        else:
            self.splice(sig.end_byte, sig.end_byte, f" -> {val}", f"set_return_type {s.qualified}")

    # -- body ops ----------------------------------------------------------

    def _body_or_fail(self, s: Symbol):
        """('body', inner_start, inner_end, body_indent, outer_indent) for a
        braced symbol, or ('nobody', semi_start, semi_end, body_indent,
        outer_indent) for a bodyless declaration like `def f() -> int;`."""
        outer = _line_indent(self.src, s.node.start_byte)
        ind = outer + _detect_indent(self.src)
        span = _brace_span(s.node)
        if span is None:
            semi = next((c for c in s.node.children if c.type == ";"), None)
            if semi is None:
                raise EditError("no_body", f"{s.qualified or s.kind} has no block body")
            return ("nobody", semi.start_byte, semi.end_byte, ind, outer)
        ob, cb = span
        return ("body", ob.end_byte, cb.start_byte, ind, outer)

    def _no_body_error(self, s: Symbol, action: str) -> EditError:
        hint = []
        if s.kind in ("ability", "function"):
            hint = [f"{s.qualified} is a bodyless declaration; if it is implemented "
                    f"in an impl block, use target='impl' name='{s.qualified}'"]
        return EditError("no_body", f"{s.qualified or s.kind} has no block body", hint)

    def op_set_body(self, op):
        s = self.must(op.get("target") or "function", op.get("name"), op.get("index"),
                      needs_body=True)
        mode, a, b, ind, outer = self._body_or_fail(s)
        code = _reindent(op["newCode"], ind)
        if mode == "nobody":
            repl = (" {\n" + code + "\n" + outer + "}") if code else " {}"
            self.splice(a, b, repl, f"set_body {s.qualified}")
            return
        inner = ("\n" + code + "\n" + outer) if code else ""
        self.splice(a, b, inner, f"set_body {s.qualified}")

    def op_replace_in_body(self, op):
        s = self.must(op.get("target") or "function", op.get("name"), op.get("index"),
                      needs_body=True)
        mode, a, b, _, _ = self._body_or_fail(s)
        if mode == "nobody":
            raise self._no_body_error(s, "replace_in_body")
        body = self.src[a:b].decode("utf-8", "replace")
        anchor = op.get("value") or ""
        hits = _find_anchor(body, anchor)
        if not hits:
            preview = body.strip("\n")[:300]
            raise EditError("anchor_not_found",
                            f"anchor {anchor[:60]!r} not in {s.qualified} body",
                            [f"body of {s.qualified} begins:\n{preview}"])
        if len(hits) > 1:
            raise EditError("ambiguous_anchor",
                            f"anchor {anchor[:60]!r} appears {len(hits)}x in {s.qualified} "
                            "body; add surrounding context or use value+valueEnd")
        start_c, end_c = hits[0]
        if op.get("valueEnd"):
            endtxt = op["valueEnd"]
            end_hits = _find_anchor(body, endtxt, end_c)
            if not end_hits:
                raise EditError("anchor_not_found",
                                f"valueEnd {endtxt[:60]!r} not found after value anchor")
            end_c = end_hits[0][1]
        # body is decoded text; splice offsets are bytes
        start = a + len(body[:start_c].encode("utf-8"))
        end = a + len(body[:end_c].encode("utf-8"))
        self.splice(start, end, op["newCode"], f"replace_in_body {s.qualified}")

    def op_add_statement(self, op):
        s = self.must(op.get("target") or "function", op.get("name"), op.get("index"),
                      needs_body=True)
        mode, a, b, ind, outer = self._body_or_fail(s)
        if mode == "nobody":
            raise self._no_body_error(s, "add_statement")
        code = _reindent(op["newCode"], ind)
        if not code:
            return
        content_end = a + len(self.src[a:b].rstrip())
        if content_end == a:  # empty body {}
            self.splice(a, b, "\n" + code + "\n" + outer, f"add_statement {s.qualified}")
        else:
            self.splice(content_end, content_end, "\n" + code, f"add_statement {s.qualified}")

    # -- structural ops ----------------------------------------------------

    def _insert_in_owner(self, s: Symbol, text: str, label, before_kinds=None):
        """Insert a member into an archetype body. Default: after the last
        member. before_kinds: on the line before the first member whose
        unwrapped type matches (has statements land on top)."""
        span = _brace_span(s.node)
        if span is None:
            raise EditError("no_body", f"{s.qualified or s.kind} has no braced body")
        ob, cb = span
        outer = _line_indent(self.src, s.node.start_byte)
        members = [_named(ch) for ch in s.node.named_children
                   if ob.end_byte <= ch.start_byte < cb.start_byte]
        ind = (_line_indent(self.src, members[0].start_byte) if members
               else outer + _detect_indent(self.src))
        text = _reindent(text, ind)
        if before_kinds:
            for first in members:
                if first.type in before_kinds:
                    line_start = self.src.rfind(b"\n", 0, first.start_byte) + 1
                    self.splice(line_start, line_start, text + "\n\n", label)
                    return
        a, b = ob.end_byte, cb.start_byte
        content_end = a + len(self.src[a:b].rstrip())
        if content_end == a:  # empty body {}
            self.splice(a, b, "\n" + text + "\n" + outer, label)
        else:
            self.splice(content_end, content_end, "\n\n" + text, label)

    def op_add_method(self, op):
        s = self.must(op.get("target") or "archetype", op.get("name"), op.get("index"),
                      needs_body=True)
        self._insert_in_owner(s, op["newCode"], f"add_method {s.qualified}",
                              before_kinds=("ability", "test"))

    def op_add_property(self, op):
        s = self.must(op.get("target") or "archetype", op.get("name"), op.get("index"),
                      needs_body=True)
        text = op["newCode"].strip()
        if not text.startswith("has ") and not text.startswith("static has"):
            text = "has " + text
        if not text.rstrip().endswith(";"):
            text = text.rstrip() + ";"
        self._insert_in_owner(s, text, f"add_property {s.qualified}",
                              before_kinds=("has_statement",))

    def op_replace(self, op):
        s = self.must(op.get("target"), op.get("name"), op.get("index"))
        self.splice(s.node.start_byte, s.node.end_byte, op["newCode"], f"replace {s.qualified or s.kind}")

    def op_add_function(self, op):
        # module-level def appended at end of file
        code = op["newCode"].rstrip() + "\n"
        self.splice(len(self.src), len(self.src), ("\n" if self.src and not self.src.endswith(b"\n\n") else "") + code, "add_function")

    # -- structural micro ops (Empryo harvest) -----------------------------

    def op_set_type(self, op):
        s = self.must(op.get("target"), op.get("name"), op.get("index"))
        val = op["value"].strip()
        ta = next((c for c in s.node.named_children
                   if c.type == "type_annotation"), None)
        if ta is not None:
            self.splice(ta.start_byte, ta.end_byte, val, f"set_type {s.qualified}")
        else:
            nm = s.node.named_children[0]  # identifier
            self.splice(nm.end_byte, nm.end_byte, f": {val}",
                        f"set_type {s.qualified}")

    def _param_list_of(self, s: Symbol) -> Node:
        sig = next((c for c in s.node.named_children
                    if c.type == "func_signature"), None)
        if sig is None:
            raise EditError("no_parameters",
                            f"{s.qualified or s.kind} has no parameter list")
        pl = next((c for c in sig.named_children
                   if c.type == "parameter_list"), None)
        if pl is None:
            raise EditError("no_parameters",
                            f"{s.qualified or s.kind} has no parameter list")
        return pl

    def op_add_parameter(self, op):
        s = self.must(op.get("target") or "ability", op.get("name"),
                      op.get("index"))
        pl = self._param_list_of(s)
        val = op["value"].strip()
        params = [c for c in pl.named_children if c.type == "param"]
        if params:
            last = params[-1]
            self.splice(last.end_byte, last.end_byte, ", " + val,
                        f"add_parameter {s.qualified}")
        else:
            cb = pl.children[-1]  # ')'
            self.splice(cb.start_byte, cb.start_byte, val,
                        f"add_parameter {s.qualified}")

    def op_remove_parameter(self, op):
        s = self.must(op.get("target") or "ability", op.get("name"),
                      op.get("index"))
        pl = self._param_list_of(s)
        want = (op.get("value") or "").strip()
        params = [c for c in pl.named_children if c.type == "param"]
        tgt = next((pm for pm in params
                    if pm.named_children
                    and _node_text(pm.named_children[0]) == want), None)
        if tgt is None:
            names = [_node_text(pm.named_children[0]) for pm in params
                     if pm.named_children]
            raise EditError(
                "parameter_not_found",
                f"no parameter named {want!r} in {s.qualified or s.kind}",
                [f"parameters: {', '.join(names)}" if names else "<none>"])
        sibs = pl.children
        i = sibs.index(tgt)
        start, end = tgt.start_byte, tgt.end_byte
        if i + 1 < len(sibs) and _node_text(sibs[i + 1]) == ",":
            end = sibs[i + 1].end_byte
        elif i - 1 >= 0 and _node_text(sibs[i - 1]) == ",":
            start = sibs[i - 1].start_byte
        self.splice(start, end, "", f"remove_parameter {s.qualified}.{want}")

    def op_set_extends(self, op):
        s = self.must(op.get("target") or "archetype", op.get("name"),
                      op.get("index"))
        kids = s.node.children
        ob_i = next((i for i, c in enumerate(kids)
                     if _node_text(c) == "("), -1)
        val = (op.get("value") or "").strip()
        if ob_i >= 0:
            cb_i = next(i for i in range(ob_i + 1, len(kids))
                        if _node_text(kids[i]) == ")")
            self.splice(kids[ob_i].end_byte, kids[cb_i].start_byte, val,
                        f"set_extends {s.qualified}")
        elif val:
            nm = _field(s.node, "name")
            self.splice(nm.end_byte, nm.end_byte, f"({val})",
                        f"set_extends {s.qualified}")

    # -- import ops ---------------------------------------------------------

    def op_add_named_import(self, op):
        module = (op.get("value") or "").strip()
        sym = (op.get("newCode") or "").strip()
        for s in (x for x in self.symbols
                  if x.kind == "import" and x.node.type == "import_statement"):
            info = _import_info(s.node)
            if info["path"] != module or not info["is_from"]:
                continue
            bare = sym.split(" as ")[0].strip()
            if any(it.split(" as ")[0].strip() == bare
                   for it in info["items"]):
                return  # idempotent — already imported
            items_node = next(c for c in s.node.children
                              if c.type == "import_items")
            named = items_node.named_children
            if named:
                last = named[-1]
                self.splice(last.end_byte, last.end_byte, ", " + sym,
                            f"add_named_import {module}.{bare}")
            else:
                cb = next(c for c in items_node.children
                          if _node_text(c) == "}")
                self.splice(cb.start_byte, cb.start_byte, sym,
                            f"add_named_import {module}.{bare}")
            return
        self.op_add_import({"value": f"import from {module} {{ {sym} }};"})

    def op_remove_import(self, op):
        module = (op.get("value") or "").strip()
        sym = (op.get("newCode") or "").strip() or None
        for s in (x for x in self.symbols
                  if x.kind == "import" and x.node.type == "import_statement"):
            info = _import_info(s.node)
            if info["path"] != module:
                continue
            if sym and info["is_from"]:
                items_node = next(c for c in s.node.children
                                  if c.type == "import_items")
                named = items_node.named_children
                ident = next((c for c in named
                              if _node_text(c).split(" as ")[0].strip() == sym),
                             None)
                if ident is None:
                    raise EditError(
                        "symbol_not_found",
                        f"{module!r} does not import {sym!r}",
                        [f"items: {', '.join(_node_text(c) for c in named)}"])
                if len(named) > 1:
                    sibs = items_node.children
                    i = sibs.index(ident)
                    start, end = ident.start_byte, ident.end_byte
                    if i + 1 < len(sibs) and _node_text(sibs[i + 1]) == ",":
                        end = sibs[i + 1].end_byte
                    elif i - 1 >= 0 and _node_text(sibs[i - 1]) == ",":
                        start = sibs[i - 1].start_byte
                    self.splice(start, end, "",
                                f"remove_import {module}.{sym}")
                    return
                # last item → remove the whole statement
            ls, le = _trim_removal(self.src, s.node.start_byte, s.node.end_byte)
            self.splice(ls, le, "", f"remove_import {module}")
            return
        raise EditError("symbol_not_found", f"no import of {module!r}",
                        ["add one with add_import first"])

    def op_organize_imports(self, op):
        imports = [s for s in self.symbols
                   if s.kind == "import" and s.node.type == "import_statement"]
        if len(imports) <= 1:
            return
        plains: dict[str, str] = {}
        froms: dict[str, list[str]] = {}
        for s in imports:
            info = _import_info(s.node)
            if info["is_from"]:
                lst = froms.setdefault(info["path"], [])
                for it in info["items"]:
                    if it not in lst:
                        lst.append(it)
            else:
                plains[info["path"]] = f"import {info['path']};"
        lines = [plains[k] for k in sorted(plains)]
        lines += [f"import from {k} {{ {', '.join(froms[k])} }};"
                  for k in sorted(froms)]
        first = imports[0].node
        self.splice(first.start_byte, first.end_byte, "\n".join(lines),
                    "organize_imports")
        for s in imports[1:]:
            ls, le = _trim_removal(self.src, s.node.start_byte, s.node.end_byte)
            self.splice(ls, le, "", "organize_imports")

    # -- module-level declaration creators ----------------------------------

    def _append_module(self, code: str, label: str):
        pre = ""
        if self.src and not self.src.endswith(b"\n\n"):
            pre = "\n" if self.src.endswith(b"\n") else "\n\n"
        self.splice(len(self.src), len(self.src), pre + code, label)

    def _after_imports_pos(self) -> int:
        imports = [s for s in self.symbols if s.kind == "import"]
        return imports[-1].node.end_byte if imports else 0

    def _wrapped(self, head: str, body: str) -> str:
        code = _reindent(body, _detect_indent(self.src))
        inner = ("\n" + code + "\n") if code else ""
        return f"{head} {{{inner}}}\n"

    def op_add_enum(self, op):
        name = (op.get("value") or "").strip()
        code = self._wrapped(f"enum {name}", op.get("newCode") or "")
        self._append_module(code, f"add_enum {name}")

    def op_add_archetype(self, op):
        kind = (op.get("target") or "obj").lower()
        if kind == "archetype":
            kind = "obj"
        if kind not in ("obj", "node", "edge", "walker", "class"):
            raise EditError(
                "bad_target",
                f"add_archetype target must be obj|node|edge|walker|class, "
                f"got {kind!r}")
        name = (op.get("value") or "").strip()
        code = self._wrapped(f"{kind} {name}", op.get("newCode") or "")
        self._append_module(code, f"add_archetype {kind} {name}")

    def op_add_glob(self, op):
        text = (op.get("newCode") or op.get("value") or "").strip()
        if not text.startswith("glob "):
            text = "glob " + text
        if not text.rstrip().endswith(";"):
            text = text.rstrip() + ";"
        pos = self._after_imports_pos()
        pre = "" if pos == 0 else "\n"
        self.splice(pos, pos, pre + text + "\n", "add_glob")

    def op_add_type_alias(self, op):
        name = (op.get("value") or "").strip()
        texp = (op.get("newCode") or "").strip().rstrip(";")
        pos = self._after_imports_pos()
        pre = "" if pos == 0 else "\n"
        self.splice(pos, pos, pre + f"type {name} = {texp};\n",
                    f"add_type_alias {name}")

    def op_add_declaration(self, op):
        """Add one module-level declaration (def, obj/node/edge/walker/class,
        enum, impl, test, glob, type alias, with entry) from its FULL text.
        glob and type aliases go after the imports; everything else is
        appended at the end of the file."""
        code = _reindent(op.get("newCode") or "", "")
        if not code:
            raise EditError("empty_code", "add_declaration needs newCode with the full declaration")
        head = code.lstrip()
        if head.startswith(("glob ", "type ")):
            pos = self._after_imports_pos()
            pre = "" if pos == 0 else "\n\n"
            self.splice(pos, pos, pre + code + ("\n" if pos == 0 else ""), "add_declaration")
            return
        self._append_module(code + "\n", "add_declaration")

    def op_add_member(self, op):
        """has-field text → add_property; anything else → add_method."""
        code = (op.get("newCode") or "").strip()
        if code.startswith(("has ", "static has ")) or (
                _FIELD_RE.match(code) and not _MEMBER_DECL_RE.match(code)):
            return self.op_add_property(op)
        return self.op_add_method(op)

    def op_add_impl(self, op):
        code = op["newCode"].strip("\n") + "\n"
        self._append_module(code, "add_impl")

    def op_add_test(self, op):
        name = (op.get("value") or "").strip()
        if not name.startswith(('"', "'")):
            name = f'"{name}"'
        code = self._wrapped(f"test {name}", op.get("newCode") or "")
        self._append_module(code, f"add_test {name}")

    # -- file ops ----------------------------------------------------------

    def op_insert_text(self, op):
        anchor = op.get("value")
        code = op["newCode"]
        if anchor == "after-imports":
            imports = [s for s in self.symbols if s.kind == "import"]
            if imports:
                last = imports[-1].node
                self.splice(last.end_byte, last.end_byte, "\n" + code, "insert_text after-imports")
                return
            pos = 0
            self.splice(0, 0, code + "\n", "insert_text after-imports")
            return
        idx = op.get("index")
        if idx is None or idx == -1:
            pos = len(self.src)
            pre = "\n" if self.src and not self.src.endswith(b"\n") else ""
            self.splice(pos, pos, pre + code + "\n", "insert_text end")
        elif idx == 0:
            self.splice(0, 0, code + "\n", "insert_text start")
        else:
            self.splice(idx, idx, code, "insert_text")

    def op_add_import(self, op):
        # `import from M { a, b };` merges into an existing from-import of M
        # (items already present are skipped); otherwise the line is added.
        m = _FROM_IMPORT_RE.match(op.get("value") or "")
        if m:
            module = m.group(1)
            items = [it.strip() for it in m.group(2).split(",") if it.strip()]
            existing = [s for s in self.symbols if s.kind == "import"
                        and _import_info(s.node)["is_from"]
                        and _import_info(s.node)["path"] == module]
            if existing and items:
                for it in items:
                    self.op_add_named_import({"value": module, "newCode": it})
                return
        # Idempotent: an identical import line is a no-op (Empryo-style merge).
        line = op["value"].rstrip() + "\n"
        norm = " ".join(line.split())
        for existing in self.src.decode("utf-8", "replace").splitlines():
            if " ".join(existing.split()) == norm.rstrip("\n"):
                return  # already present — merge semantics
        imports = [s for s in self.symbols if s.kind == "import"]
        if imports:
            last = imports[-1].node
            self.splice(last.end_byte, last.end_byte, "\n" + line.rstrip("\n"), "add_import")
        else:
            self.splice(0, 0, line, "add_import")


OPS = {
    "rename": Engine.op_rename,
    "remove": Engine.op_remove,
    "set_initializer": Engine.op_set_initializer,
    "set_return_type": Engine.op_set_return_type,
    "set_body": Engine.op_set_body,
    "replace_in_body": Engine.op_replace_in_body,
    "add_statement": Engine.op_add_statement,
    "add_method": Engine.op_add_method,
    "add_property": Engine.op_add_property,
    "add_member": Engine.op_add_member,
    "add_declaration": Engine.op_add_declaration,
    "replace": Engine.op_replace,
    "add_function": Engine.op_add_function,
    "insert_text": Engine.op_insert_text,
    "add_import": Engine.op_add_import,
    "set_type": Engine.op_set_type,
    "add_parameter": Engine.op_add_parameter,
    "remove_parameter": Engine.op_remove_parameter,
    "set_extends": Engine.op_set_extends,
    "add_named_import": Engine.op_add_named_import,
    "remove_import": Engine.op_remove_import,
    "organize_imports": Engine.op_organize_imports,
    "add_enum": Engine.op_add_enum,
    "add_archetype": Engine.op_add_archetype,
    "add_glob": Engine.op_add_glob,
    "add_type_alias": Engine.op_add_type_alias,
    "add_impl": Engine.op_add_impl,
    "add_test": Engine.op_add_test,
}


# --------------------------------------------------------------------------
# entry points


def _symbol_payload(src: bytes) -> dict:
    tree = new_parser().parse(src)
    out = []
    for s in _index_symbols(tree.root_node):
        n = s.node
        out.append({
            "kind": s.kind,
            "name": s.name,
            "qualified": s.qualified or None,
            "parent": s.parent,
            "index": s.index,
            "startLine": n.start_point[0] + 1,
            "endLine": n.end_point[0] + 1,
            "startCol": n.start_point[1],
            "detail": _node_text(n).split("\n")[0][:100],
        })
    return {"symbols": out, "hasErrors": tree.root_node.has_error}


def cmd_symbols(path: Path) -> dict:
    return _symbol_payload(path.read_bytes())


SKIP_SEARCH_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".venv",
    "venv",
    "env",
    "node_modules",
    "dist",
    "build",
    "target",
    "__pycache__",
    ".mypy_cache",
    ".pytest_cache",
    ".ruff_cache",
}


# --------------------------------------------------------------------------
# persistent symbol-index cache

CACHE_VERSION = 2  # bump when _symbol_payload output shape or indexing changes


def _cache_path(root: Path) -> Path | None:
    """Per-root cache file under jac_check.cache_root()."""
    try:
        resolved = str(root.resolve())
    except OSError:
        return None
    key = hashlib.sha256(resolved.encode("utf-8")).hexdigest()[:16]
    return jac_check.cache_root() / f"{key}.json"


def _stat_key(path: Path) -> dict | None:
    try:
        st = path.stat()
    except OSError:
        return None
    return {"mtime": st.st_mtime_ns, "size": st.st_size}


def _load_cache(root: Path) -> dict:
    if os.environ.get("JAC_AST_EDIT_NO_CACHE"):
        return {}
    cache_file = _cache_path(root)
    if cache_file is None:
        return {}
    try:
        data = json.loads(cache_file.read_text())
    except (OSError, ValueError):
        return {}
    if not isinstance(data, dict) or data.get("v") != CACHE_VERSION:
        return {}
    files = data.get("files")
    return files if isinstance(files, dict) else {}


def _save_cache(root: Path, files: dict) -> None:
    if os.environ.get("JAC_AST_EDIT_NO_CACHE"):
        return
    cache_file = _cache_path(root)
    if cache_file is None:
        return
    tmp = cache_file.with_name(f"{cache_file.name}.{os.getpid()}.tmp")
    try:
        cache_file.parent.mkdir(parents=True, exist_ok=True)
        tmp.write_text(json.dumps({"v": CACHE_VERSION, "files": files}))
        os.replace(tmp, cache_file)  # atomic: concurrent readers never see a partial cache
    except OSError:
        try:
            tmp.unlink()
        except OSError:
            pass


def _index_with_cache(root: Path) -> tuple[list[tuple[Path, dict]], dict]:
    """Symbol payloads for every .jac file under root, in walk order.

    Reuses cached payloads for files whose mtime_ns+size are unchanged since
    the last run; re-parses new/changed files and prunes deleted ones (anything
    not walked no longer lands in the saved set). Returns ([(path, payload)],
    {"reused": n, "parsed": n}). Read failures yield an {"error": ...} payload
    that is NOT cached, so the next run retries them.
    """
    cache = _load_cache(root)
    merged: dict[str, dict] = {}
    out: list[tuple[Path, dict]] = []
    reused = 0
    parsed = 0
    for file in _iter_jac_files(root):
        try:
            key = str(file.resolve())
        except OSError:
            continue
        entry = cache.get(key)
        stat = _stat_key(file)
        if (stat and isinstance(entry, dict) and "symbols" in entry
                and "hasErrors" in entry
                and entry.get("mtime") == stat["mtime"]
                and entry.get("size") == stat["size"]):
            reused += 1
            merged[key] = entry
            out.append((file, entry))
            continue
        try:
            payload = _symbol_payload(file.read_bytes())
        except Exception as e:  # noqa: BLE001 — surfaced as data, retried next run
            out.append((file, {"symbols": [], "hasErrors": False, "error": str(e)}))
            continue
        parsed += 1
        stat = _stat_key(file) or {}
        entry = {"mtime": stat.get("mtime"), "size": stat.get("size"),
                 "symbols": payload["symbols"], "hasErrors": payload["hasErrors"]}
        merged[key] = entry
        out.append((file, payload))
    _save_cache(root, merged)
    return out, {"reused": reused, "parsed": parsed}


def _display_path(path: Path, base: Path) -> str:
    try:
        return path.resolve().relative_to(base.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def _glob_match(rel: str, path_glob: str) -> bool:
    """fnmatch, where a leading '**/' also matches files at the top level."""
    if fnmatch.fnmatch(rel, path_glob):
        return True
    return path_glob.startswith("**/") and fnmatch.fnmatch(rel, path_glob[3:])


def _iter_files(root: Path, path_glob: str | None = None, jac_only: bool = True):
    """Files under root in sorted walk order, skipping SKIP_SEARCH_DIRS.
    jac_only=False admits any file the glob matches (text search)."""
    if root.is_file():
        if not jac_only or root.suffix == ".jac":
            yield root
        return
    stack = [root]
    while stack:
        cur = stack.pop()
        try:
            entries = sorted(cur.iterdir(), key=lambda p: p.name)
        except OSError:
            continue
        for entry in entries:
            if entry.is_dir():
                if entry.name in SKIP_SEARCH_DIRS:
                    continue
                stack.append(entry)
            elif entry.suffix == ".jac" or (not jac_only and entry.is_file()):
                if path_glob and not _glob_match(_display_path(entry, root), path_glob):
                    continue
                yield entry


def _iter_jac_files(root: Path, path_glob: str | None = None):
    if root.is_file():
        if root.suffix == ".jac":
            yield root
        return

    stack = [root]
    while stack:
        cur = stack.pop()
        try:
            entries = sorted(cur.iterdir(), key=lambda p: p.name)
        except OSError:
            continue
        for entry in entries:
            if entry.is_dir():
                if entry.name in SKIP_SEARCH_DIRS:
                    continue
                stack.append(entry)
            elif entry.suffix == ".jac":
                if path_glob:
                    rel = _display_path(entry, root)
                    if not fnmatch.fnmatch(rel, path_glob):
                        continue
                yield entry


def _symbol_matches(sym: dict, query: str, kind: str | None, exact: bool) -> bool:
    if kind and not _kind_matches(kind, str(sym.get("kind") or "").lower()):
        return False
    if not query:
        return True
    haystack = [
        str(sym.get("name") or ""),
        str(sym.get("qualified") or ""),
        str(sym.get("detail") or ""),
    ]
    q = query.lower()
    if exact:
        return any(item.lower() == q for item in haystack if item)
    return any(q in item.lower() for item in haystack if item)


DEFAULT_LIMIT = 100
DEFAULT_TEXT_LIMIT = 50
MAX_LIMIT = 500
TEXT_MAX_FILE_BYTES = 2_000_000


def _limit(payload: dict, default: int) -> int:
    try:
        return max(1, min(int(payload.get("limit") or default), MAX_LIMIT))
    except (TypeError, ValueError):
        return default


def _enclosing(symbols: list[dict], line: int) -> dict | None:
    """Innermost indexed symbol whose line range covers `line` (1-based)."""
    best = None
    for sym in symbols:
        if sym.get("kind") == "import":
            continue
        a, b = sym.get("startLine", 0), sym.get("endLine", 0)
        if a <= line <= b and (best is None or b - a < best["endLine"] - best["startLine"]):
            best = sym
    return best


def _search_text(root: Path, payload: dict) -> dict:
    """Literal text search inside files, each hit labelled with its innermost
    enclosing Jac symbol. Smart case: case-insensitive unless the query has an
    uppercase letter. .jac files only, unless pathGlob selects others."""
    query = str(payload.get("query") or "")
    if not query.strip():
        return {"error": {"code": "no_query", "message": "mode 'text' needs a query"}}
    path_glob = payload.get("pathGlob")
    path_glob = str(path_glob).strip() if path_glob else None
    limit = _limit(payload, DEFAULT_TEXT_LIMIT)
    fold = query == query.lower()
    needle = query.lower() if fold else query
    display_base = Path(payload.get("cwd") or (root.parent if root.is_file() else root))

    index: dict[str, list[dict]] = {}
    if path_glob is None or path_glob.endswith(".jac") or "*" in path_glob:
        entries, _ = _index_with_cache(root)
        index = {str(f.resolve()): r.get("symbols", []) for f, r in entries}

    matches = []
    scanned = 0
    truncated = False
    for file in _iter_files(root, path_glob, jac_only=path_glob is None):
        try:
            if file.stat().st_size > TEXT_MAX_FILE_BYTES:
                continue
            data = file.read_bytes()
        except OSError:
            continue
        if b"\0" in data[:8192]:
            continue  # binary
        scanned += 1
        syms = index.get(str(file.resolve()), [])
        rel = _display_path(file, display_base)
        for no, text in enumerate(data.decode("utf-8", "replace").split("\n"), 1):
            if needle not in (text.lower() if fold else text):
                continue
            if len(matches) >= limit:
                truncated = True
                break
            enc = _enclosing(syms, no) if file.suffix == ".jac" else None
            matches.append({"path": rel, "line": no, "text": text.strip()[:160],
                            "kind": enc.get("kind") if enc else None,
                            "qualified": enc.get("qualified") if enc else None})
        if truncated:
            break
    return {"ok": True, "mode": "text", "query": query, "scannedFiles": scanned,
            "parseErrorFiles": 0, "matches": matches, "files": [], "truncated": truncated}


def format_search(result: dict) -> str:
    """Model-facing text for a search result."""
    mode = result.get("mode", "symbols")
    scanned = result.get("scannedFiles", 0)
    parse_errors = result.get("parseErrorFiles", 0)
    noun = "file" if mode == "text" else ".jac file"
    suffix = ", ".join(x for x in (
        f"scanned {scanned} {noun}{'' if scanned == 1 else 's'}",
        f"{parse_errors} parse-error file{'' if parse_errors == 1 else 's'}" if parse_errors else "",
        "truncated: narrow the query or raise limit" if result.get("truncated") else "",
    ) if x)
    if mode == "files":
        files = result.get("files", [])
        if not files:
            return f"No Jac files found ({suffix})."
        rows = [f"{len(files)} Jac file{'' if len(files) == 1 else 's'} ({suffix}):"]
        for f in files:
            extra = " parse-errors" if f.get("hasErrors") else ""
            extra += f" error={f['error']}" if f.get("error") else ""
            rows.append(f"  {f['path']} ({f.get('symbolCount', 0)} symbols{extra})")
        return "\n".join(rows)
    matches = result.get("matches", [])
    if mode == "text":
        if not matches:
            return f"No text matches for {result.get('query')!r} ({suffix})."
        rows = [f"{len(matches)} text match{'' if len(matches) == 1 else 'es'} ({suffix}):"]
        for m in matches:
            where = (f" [{m['kind']} {m['qualified']}]" if m.get("qualified")
                     else f" [{m['kind']}]" if m.get("kind") else "")
            rows.append(f"  {m['path']}:{m['line']}{where} {m['text']}")
        return "\n".join(rows)
    if not matches:
        return (f"No AST symbol matches ({suffix}). Symbol search only looks at names and "
                "declaration lines; use mode 'text' to search inside bodies.")
    rows = [f"{len(matches)} AST symbol match{'' if len(matches) == 1 else 'es'} ({suffix}):"]
    for m in matches:
        label = m.get("qualified") or m.get("name") or (m.get("detail") if m.get("kind") == "import" else None) or "<anonymous>"
        rng = f"{m['startLine']}-{m['endLine']}" if m["endLine"] != m["startLine"] else str(m["startLine"])
        rows.append(f"  {m['path']}:{rng} {m['kind']} {label}")
    return "\n".join(rows)


def cmd_search(root: Path, payload: dict) -> dict:
    """Repository-level AST discovery for Jac.

    This is intentionally not grep: candidate files are parsed with the Jac
    tree-sitter grammar and results come from the symbol index, which is
    cached across runs (_index_with_cache) and updated incrementally.
    """
    mode = str(payload.get("mode") or "symbols")
    if mode not in {"symbols", "outline", "files", "text"}:
        return {"error": {"code": "bad_mode", "message": "mode must be symbols, outline, files, or text"}}
    if mode == "text":
        return _search_text(root, payload)

    query = str(payload.get("query") or "").strip()
    kind = payload.get("kind")
    kind = str(kind).strip() if kind else None
    exact = bool(payload.get("exact") or False)
    path_glob = payload.get("pathGlob")
    path_glob = str(path_glob).strip() if path_glob else None
    limit = _limit(payload, DEFAULT_LIMIT)

    display_base = Path(payload.get("cwd") or (root.parent if root.is_file() else root))
    entries, cache_stats = _index_with_cache(root)
    matches = []
    files = []
    scanned = 0
    parse_errors = 0
    truncated = False

    for file, result in entries:
        if path_glob and not _glob_match(_display_path(file, root), path_glob):
            continue
        scanned += 1
        rel = _display_path(file, display_base)
        if result.get("error"):  # read/parse failure — not cached, retried next run
            parse_errors += 1
            if mode == "files":
                files.append({"path": rel, "error": str(result["error"]), "symbolCount": 0})
            continue

        syms = result.get("symbols", [])
        has_errors = bool(result.get("hasErrors"))
        if has_errors:
            parse_errors += 1

        if mode == "files":
            if not query or query.lower() in rel.lower():
                files.append({
                    "path": rel,
                    "symbolCount": len(syms),
                    "hasErrors": has_errors,
                })
                if len(files) >= limit:
                    truncated = True
                    break
            continue

        file_matches = []
        for sym in syms:
            if mode == "outline" or _symbol_matches(sym, query, kind, exact):
                row = {"path": rel, **sym}
                file_matches.append(row)

        if mode == "outline":
            if query and query.lower() not in rel.lower() and not any(
                _symbol_matches(sym, query, kind, exact) for sym in syms
            ):
                continue

        for row in file_matches:
            matches.append(row)
            if len(matches) >= limit:
                truncated = True
                break
        if truncated:
            break

    return {
        "ok": True,
        "mode": mode,
        "root": _display_path(root, display_base),
        "query": query or None,
        "kind": kind,
        "exact": exact,
        "scannedFiles": scanned,
        "parseErrorFiles": parse_errors,
        "indexCache": cache_stats,
        "matches": matches,
        "files": files,
        "truncated": truncated,
    }


def apply_batch(path: Path, operations: list[dict], dry_run=False) -> dict:
    """Apply ops sequentially: each op re-parses the CURRENT source, so spans
    stay valid even when an earlier op nests inside a later one's region.
    Atomicity is preserved at the write level: nothing is written until every
    op has applied and the final source passes the re-parse check."""
    src = path.read_bytes()
    base_errors = _count_errors(new_parser().parse(src).root_node)
    cur = src
    results = []
    for i, op in enumerate(operations):
        action = op.get("action")
        fn = OPS.get(action)
        if fn is None or not callable(fn):
            raise EditError("unknown_action", f"unknown action {action!r}",
                            [f"known: {', '.join(sorted(k for k in OPS))}"])
        tree = new_parser().parse(cur)
        eng = Engine(cur, tree)
        try:
            fn(eng, op)
            results.append({"op": i, "action": action, "ok": True})
        except EditError as e:
            e.message = f"op[{i}] {action}: {e.message}"
            raise
        for a, b, repl, _label in sorted(eng.splices, key=lambda t: -t[0]):
            cur = cur[:a] + repl + cur[b:]
    newtree = new_parser().parse(cur)
    new_errors = _count_errors(newtree.root_node)
    if new_errors > base_errors:
        old_ex = src.decode("utf-8", "replace")
        new_ex = cur.decode("utf-8", "replace")
        import difflib
        diff = "\n".join(list(difflib.unified_diff(
            old_ex.split("\n"), new_ex.split("\n"), lineterm=""))[2:40])
        raise EditError(
            "syntax_regressed",
            f"batch rejected: parse errors {base_errors} -> {new_errors}; nothing written",
            [diff[:2000]],
        )
    if not dry_run and cur != src:
        path.write_bytes(cur)
    return {
        "ok": True,
        "_source": cur,
        "changed": cur != src,
        "applied": results,
        "bytes": {"before": len(src), "after": len(cur)},
        "lines": {"before": src.count(b"\n") + 1, "after": cur.count(b"\n") + 1},
        "errors": {"before": base_errors, "after": new_errors},
    }


def _view_symbols(src: bytes) -> list[tuple[int, int, str, str]]:
    root = new_parser().parse(src).root_node
    return [(s.node.start_point[0], s.node.end_point[0], s.kind, s.qualified or s.kind)
            for s in _index_symbols(root)]


def cmd_edit(path: Path, payload: dict) -> dict:
    """Apply a batch, then build the model-facing report: summary line,
    view of the changed code, and the NEW `jac check` errors."""
    ops = payload.get("operations")
    if not ops:
        return {"error": {"code": "no_ops", "message": "body must be {\"operations\": [...]}"}}
    display = str(payload.get("displayPath") or path)
    original = path.read_bytes()
    res = apply_batch(path, ops, dry_run=True)
    new_src = res.pop("_source")
    actions = [a["action"] for a in res["applied"]]
    head = (f"{actions[0]} ok" if len(actions) == 1
            else f"{len(actions)} ops ok (atomic): {', '.join(actions)}")
    if not res["changed"]:
        res["report"] = head + " (no change: already present)"
        return res
    dl = res["lines"]["after"] - res["lines"]["before"]
    if dl:
        head += f" (lines {'+' if dl > 0 else ''}{dl})"
    if res["errors"]["after"] > 0:
        head += f" [file has {res['errors']['after']} pre-existing parse error(s)]"

    check_before = None
    check_on = payload.get("check", True) and jac_check.enabled()
    if check_on:
        check_before = jac_check.cached_diags(path, original)
        if check_before is None:
            r = jac_check.run_check(path, payload.get("cwd"))
            check_before = r["diags"] if r["ok"] else None
            if r["ok"]:
                jac_check.store_diags(path, original, check_before)
    path.write_bytes(new_src)

    old_t = original.decode("utf-8", "replace")
    new_t = new_src.decode("utf-8", "replace")
    parts = [head]
    view = edit_view.render(old_t, new_t, display, _view_symbols(new_src))
    if view:
        parts.append(view)
    if check_on:
        r = jac_check.run_check(path, payload.get("cwd"))
        res["checkSeconds"] = round(r["seconds"], 2)
        if r["ok"]:
            jac_check.store_diags(path, new_src, r["diags"])
            before = check_before or []
            new = jac_check.new_diagnostics(before, r["diags"],
                                            edit_view.changed_line_numbers(old_t, new_t))
            fixed = max(0, len(before) - (len(r["diags"]) - len(new)))
            parts.append(jac_check.format_report(display, new, len(r["diags"]), fixed,
                                                 no_baseline=check_before is None))
            res["newDiagnostics"] = len(new)
        else:
            parts.append(jac_check.format_report(display, [], 0, 0, r["error"]))
    res["report"] = "\n".join(parts)
    return res


def main(argv):
    if len(argv) < 2:
        print(json.dumps({"error": {"code": "usage", "message": "usage: jac_ast_edit.py symbols|search|edit <file-or-root>"}}))
        return 2
    cmd, filearg = argv[0], argv[1]
    path = Path(filearg)
    if cmd == "create":
        payload = json.loads(sys.stdin.read() or "{}")
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.exists() and not payload.get("overwrite"):
            return _out({"error": {"code": "exists", "message": f"{path} exists; pass overwrite:true"}})
        path.write_text(payload.get("content", ""))
        return _out({"ok": True, "created": str(path)})
    if not path.exists():
        return _out({"error": {"code": "no_file", "message": f"{path} not found"}})
    if cmd == "search":
        try:
            payload = json.loads(sys.stdin.read() or "{}")
            res = cmd_search(path, payload)
            if "error" not in res:
                res["report"] = format_search(res)
            return _out(res)
        except json.JSONDecodeError as e:
            return _out({"error": {"code": "bad_json", "message": str(e)}}, 0)
        except Exception as e:  # noqa: BLE001 — surfaced as JSON
            return _out({"error": {"code": "search_failed", "message": str(e)}}, 0)
    if cmd == "symbols":
        try:
            return _out(cmd_symbols(path))
        except Exception as e:  # noqa: BLE001 — surfaced as JSON
            return _out({"error": {"code": "symbols_failed", "message": str(e)}}, 0)
    if cmd == "edit":
        try:
            payload = json.loads(sys.stdin.read() or "{}")
            if payload.get("dryRun"):
                res = apply_batch(path, payload.get("operations") or [], dry_run=True)
                res.pop("_source", None)
                return _out(res)
            return _out(cmd_edit(path, payload))
        except EditError as e:
            return _out({"error": {"code": e.code, "message": e.message,
                                   "suggestions": e.suggestions}}, 0)
        except json.JSONDecodeError as e:
            return _out({"error": {"code": "bad_json", "message": str(e)}}, 0)
    return _out({"error": {"code": "usage", "message": f"unknown command {cmd!r}"}})


def _out(obj, ok_exit=0) -> int:
    print(json.dumps(obj, indent=1))
    return ok_exit if "error" not in obj else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
