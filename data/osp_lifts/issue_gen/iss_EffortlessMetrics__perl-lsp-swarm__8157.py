"""EffortlessMetrics/perl-lsp-swarm#8157 — recursive document-symbol projection."""

from __future__ import annotations

from collections import deque

KIND_RANK = {
    "package": 0,
    "class": 1,
    "role": 2,
    "method": 3,
    "sub": 4,
    "field": 5,
    "constant": 6,
    "variable": 7,
    "lexical": 99,
}


class DeclarationGraph:
    def __init__(self) -> None:
        self._decls: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._body_members: dict[str, list[str]] = {}
        self._reach: dict[str, list[str]] = {}
        self._meta: dict[str, dict] = {}


def load_declaration_graph(
    declarations: list[str],
    parent_of: list[tuple[str, str | None]],
    body_members: list[tuple[str, str]],
    meta: dict[str, dict],
    reach_edges: list[tuple[str, str]] | None = None,
) -> DeclarationGraph:
    g = DeclarationGraph()
    for did in declarations:
        g._decls.add(did)
        g._parent.setdefault(did, None)
        g._children.setdefault(did, [])
        g._body_members.setdefault(did, [])
        g._reach.setdefault(did, [])
    for child, parent in parent_of:
        if child in g._decls:
            if parent is None or parent in g._decls:
                g._parent[child] = parent
                if parent is not None:
                    g._children[parent].append(child)
            else:
                g._parent[child] = None
    for owner, member in body_members:
        if owner in g._decls and member in g._decls:
            g._body_members[owner].append(member)
    for did, row in meta.items():
        if did in g._decls:
            g._meta[did] = dict(row)
    for src, dst in reach_edges or []:
        if src in g._decls and dst in g._decls and dst not in g._reach[src]:
            g._reach[src].append(dst)
    return g


def outline_visible(kind: str, provenance: str) -> bool:
    if provenance != "source-backed":
        return False
    return kind not in ("lexical", "block", "anon")


def source_sort_key(g: DeclarationGraph, decl_id: str) -> tuple:
    row = g._meta[decl_id]
    return (
        row["start"],
        row["end"],
        KIND_RANK.get(row["kind"], 50),
        decl_id,
    )


def _sorted_ids(g: DeclarationGraph, ids: list[str]) -> list[str]:
    return sorted(ids, key=lambda did: source_sort_key(g, did))


def _member_ids(g: DeclarationGraph, container_id: str) -> list[str]:
    body = g._body_members.get(container_id, [])
    if body:
        return _sorted_ids(g, body)
    direct = [c for c in g._children.get(container_id, []) if g._parent.get(c) == container_id]
    return _sorted_ids(g, direct)


def _project_decl(g: DeclarationGraph, decl_id: str, claimed: set[str]) -> list[dict]:
    if decl_id in claimed or decl_id not in g._decls:
        return []
    row = g._meta[decl_id]
    if not outline_visible(row["kind"], row["provenance"]):
        hoisted: list[dict] = []
        for child_id in _member_ids(g, decl_id):
            hoisted.extend(_project_decl(g, child_id, claimed))
        return hoisted
    claimed.add(decl_id)
    node = {"id": decl_id, "name": row["name"], "kind": row["kind"], "children": []}
    for child_id in _member_ids(g, decl_id):
        for sub in _project_decl(g, child_id, claimed):
            node["children"].append(sub)
    return [node]


def project_document_symbols(g: DeclarationGraph) -> list[dict]:
    roots = [did for did in g._decls if g._parent.get(did) is None]
    claimed: set[str] = set()
    forest: list[dict] = []
    for root_id in _sorted_ids(g, roots):
        forest.extend(_project_decl(g, root_id, claimed))
    return forest


def flatten_identities(forest: list[dict]) -> list[str]:
    out: list[str] = []
    stack = list(reversed(forest))
    while stack:
        node = stack.pop()
        out.append(node["id"])
        for child in reversed(node.get("children", [])):
            stack.append(child)
    return out


def visible_descendants(g: DeclarationGraph, anchor_id: str) -> list[str]:
    if anchor_id not in g._decls:
        return []
    seen: set[str] = {anchor_id}
    q: deque[str] = deque([anchor_id])
    found: list[str] = []
    while q:
        cur = q.popleft()
        for nxt in _sorted_ids(g, g._children.get(cur, [])):
            if nxt in seen:
                continue
            seen.add(nxt)
            row = g._meta[nxt]
            if outline_visible(row["kind"], row["provenance"]):
                found.append(nxt)
            q.append(nxt)
    return _sorted_ids(g, found) if found else []


def declaration_reach(g: DeclarationGraph, start_id: str) -> list[str]:
    if start_id not in g._decls:
        return []
    seen: set[str] = {start_id}
    q: deque[str] = deque([start_id])
    order: list[str] = []
    while q:
        cur = q.popleft()
        nbrs: list[str] = []
        nbrs.extend(g._children.get(cur, []))
        nbrs.extend(g._reach.get(cur, []))
        for nxt in _sorted_ids(g, nbrs):
            if nxt in seen:
                continue
            seen.add(nxt)
            order.append(nxt)
            q.append(nxt)
    return order
