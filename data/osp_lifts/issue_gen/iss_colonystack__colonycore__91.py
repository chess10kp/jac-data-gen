"""Synthetic pre-OSP graph machinery for colonystack/colonycore#91.

Postgres benchmark suite prototype: relationship traversal probes over
in-memory entity graphs (Colony/Subject/Assignment/Protocol).
"""
from __future__ import annotations

from collections import deque
from typing import Any


def _fixture() -> dict[str, Any]:
    parent_of: dict[str, str | None] = {
        "col_a": None, "sub_1": "col_a", "sub_2": "col_a",
        "asn_1": "sub_1", "asn_2": "sub_1", "asn_3": "sub_2",
        "prt_p": None, "stp_1": "prt_p", "stp_2": "prt_p", "stp_3": "prt_p",
        "ver_1": "stp_1", "ver_2": "stp_2",
    }
    children_of: dict[str, list[str]] = {}
    for child, par in parent_of.items():
        if par is not None:
            children_of.setdefault(par, []).append(child)
    for key in children_of:
        children_of[key] = sorted(children_of[key])
    outbound: dict[str, dict[str, list[str]]] = {
        "colony_subject": {"col_a": ["sub_1", "sub_2"]},
        "subject_assignment": {"sub_1": ["asn_1", "asn_2"], "sub_2": ["asn_3"]},
        "protocol_step": {"prt_p": ["stp_1", "stp_2", "stp_3"]},
    }
    return {"parent_of": parent_of, "children_of": children_of, "outbound": outbound}


def get_ancestors(entity_id: str, *, max_depth: int = 16) -> list[str]:
    st = _fixture()
    if entity_id not in st["parent_of"]:
        return []
    found: list[str] = []
    claimed: dict[str, bool] = {}

    def step(eid: str, depth: int) -> None:
        if eid in claimed:
            return
        claimed[eid] = True
        if depth >= max_depth:
            return
        par = st["parent_of"].get(eid)
        if par is None or par in claimed:
            return
        found.append(par)
        step(par, depth + 1)

    step(entity_id, 0)
    return sorted(found)


def get_descendants(entity_id: str, *, max_depth: int = 16) -> list[str]:
    st = _fixture()
    if entity_id not in st["parent_of"]:
        return []
    reached: list[str] = []
    claimed: dict[str, bool] = {}

    def step(eid: str, depth: int) -> None:
        if eid in claimed:
            return
        claimed[eid] = True
        if eid != entity_id:
            reached.append(eid)
        if depth >= max_depth:
            return
        for child in st["children_of"].get(eid, []):
            step(child, depth + 1)

    step(entity_id, 0)
    return sorted(reached)


def traverse_rel_chain(start_id: str, rel_kinds: tuple[str, ...]) -> list[str]:
    if len(rel_kinds) == 0:
        return []
    st = _fixture()
    active = [start_id]
    reached_claim: dict[str, bool] = {}
    reached: list[str] = []
    for kind in rel_kinds:
        nxt: list[str] = []
        for src_id in active:
            for tgt_id in st["outbound"].get(kind, {}).get(src_id, []):
                if tgt_id not in reached_claim:
                    reached_claim[tgt_id] = True
                    reached.append(tgt_id)
                    nxt.append(tgt_id)
        active = sorted(nxt)
    return sorted(reached)


def list_rel_targets(entity_id: str, rel_kind: str) -> list[str]:
    st = _fixture()
    return sorted(st["outbound"].get(rel_kind, {}).get(entity_id, []))


def traversal_probe(entity_id: str) -> dict[str, int]:
    st = _fixture()
    if entity_id not in st["parent_of"]:
        return {"visited": 0, "edges": 0, "depth": 0}
    ancestors = get_ancestors(entity_id)
    descendants = get_descendants(entity_id)
    seen: dict[str, bool] = {entity_id: True}
    for a in ancestors:
        seen[a] = True
    for d in descendants:
        seen[d] = True
    visited = 0
    for _ in seen:
        visited += 1
    return {"visited": visited, "edges": len(ancestors) + len(descendants), "depth": len(ancestors)}
