"""kuzudb/kuzu#5152 — pairwise hop reach vs bounded backward C closure."""

from __future__ import annotations

from collections import deque

KIND_A = "A"
KIND_C = "C"
KIND_ATTR = "Attribute"


class GraphNode:
    def __init__(self, nid: str, kind: str, name: str = "") -> None:
        self.nid = nid
        self.kind = kind
        self.name = name


class GraphStore:
    def __init__(self) -> None:
        self.nodes: dict[str, GraphNode] = {}
        self._to_attr: dict[str, list[str]] = {}
        self._from_attr: dict[str, list[str]] = {}
        self._incoming_to_attr: dict[str, list[str]] = {}
        self._incoming_from_attr: dict[str, list[str]] = {}


def _two_hop_c_targets(a_id: str, store: GraphStore) -> list[str]:
    out: list[str] = []
    for attr_id in sorted(store._to_attr.get(a_id, [])):
        for tgt_id in sorted(store._from_attr.get(attr_id, [])):
            if store.nodes[tgt_id].kind == KIND_C:
                out.append(tgt_id)
    return out


def _backward_collect(anchor_id: str, max_depth: int, store: GraphStore) -> list[str]:
    claimed: dict[str, bool] = {}
    found: list[str] = []
    depth: dict[str, int] = {anchor_id: 0}
    stack: deque[str] = deque([anchor_id])
    while stack:
        here_id = stack.pop()
        if here_id in claimed:
            continue
        cur = depth.get(here_id, 0)
        if cur > max_depth:
            continue
        claimed[here_id] = True
        nd = store.nodes[here_id]
        if nd.kind == KIND_C and cur < max_depth:
            found.append(here_id)
        if cur < max_depth:
            preds: list[str] = []
            for attr_id in store._incoming_from_attr.get(here_id, []):
                for pred_id in store._incoming_to_attr.get(attr_id, []):
                    preds.append(pred_id)
            ordered = sorted(preds)
            for pred_id in ordered:
                if pred_id not in depth:
                    depth[pred_id] = cur + 1
                stack.append(pred_id)
    return sorted(found)


def fresh_graph_store() -> GraphStore:
    return GraphStore()


def register_node(
    nid: str,
    kind: str,
    name: str = "",
    store: GraphStore | None = None,
) -> GraphStore:
    s = store
    if s is None:
        s = fresh_graph_store()
    if nid in s.nodes:
        raise ValueError("duplicate node id")
    s.nodes[nid] = GraphNode(nid=nid, kind=kind, name=name)
    s._to_attr.setdefault(nid, [])
    return s


def add_pair_hop(from_id: str, attr_id: str, to_id: str, store: GraphStore) -> None:
    if from_id not in store.nodes or attr_id not in store.nodes or to_id not in store.nodes:
        raise KeyError("unknown node id")
    store._to_attr.setdefault(from_id, []).append(attr_id)
    store._incoming_to_attr.setdefault(attr_id, []).append(from_id)
    store._from_attr.setdefault(attr_id, []).append(to_id)
    store._incoming_from_attr.setdefault(to_id, []).append(attr_id)


def two_hop_targets(a_id: str, store: GraphStore) -> list[str]:
    if a_id not in store.nodes:
        raise KeyError(a_id)
    if store.nodes[a_id].kind != KIND_A:
        return []
    return sorted(_two_hop_c_targets(a_id, store))


def count_two_hop_a_to_c(store: GraphStore) -> int:
    total = 0
    for nid in sorted(store.nodes.keys()):
        if store.nodes[nid].kind != KIND_A:
            continue
        total += len(_two_hop_c_targets(nid, store))
    return total


def backward_c_reach(anchor_id: str, max_depth: int, store: GraphStore) -> list[str]:
    if anchor_id not in store.nodes:
        raise KeyError(anchor_id)
    return _backward_collect(anchor_id, max_depth, store)


def count_backward_c_reach(anchor_name: str, max_depth: int, store: GraphStore) -> int:
    anchor_id = ""
    for nid, nd in store.nodes.items():
        if nd.kind == KIND_C and nd.name == anchor_name:
            anchor_id = nid
    if anchor_id == "":
        return 0
    return len(backward_c_reach(anchor_id, max_depth, store))


def query_row_count(anchor_name: str, max_depth: int, store: GraphStore) -> int:
    anchor_id = ""
    for nid, nd in store.nodes.items():
        if nd.kind == KIND_C and nd.name == anchor_name:
            anchor_id = nid
    if anchor_id == "":
        return 0
    reach_set = {cid: True for cid in backward_c_reach(anchor_id, max_depth, store)}
    rows = 0
    for nid in sorted(store.nodes.keys()):
        if store.nodes[nid].kind != KIND_A:
            continue
        for tgt in _two_hop_c_targets(nid, store):
            if reach_set.get(tgt, False):
                rows += 1
    return rows
