"""jaypipes/articles#37 — bounded-depth hierarchy adjacency and recursive reach."""

from __future__ import annotations

from collections import deque

TRAIT_GPU = "gpu"
TRAIT_CPU = "cpu"


class _ResNode:
    __slots__ = ("nid", "resources", "traits", "tree_out", "group_out")

    def __init__(self, nid: str, resources: int, traits: str) -> None:
        self.nid = nid
        self.resources = resources
        self.traits = traits
        self.tree_out: list[_ResNode] = []
        self.group_out: list[_ResNode] = []


def _sorted_tree_out(nd: _ResNode) -> list[_ResNode]:
    kids = list(nd.tree_out)
    kids.sort(key=lambda ch: ch.nid)
    return kids


def _sorted_closure_out(nd: _ResNode) -> list[_ResNode]:
    kids = list(nd.tree_out) + list(nd.group_out)
    kids.sort(key=lambda ch: ch.nid)
    ordered: list[_ResNode] = []
    seen: set[str] = set()
    for ch in kids:
        if ch.nid in seen:
            continue
        seen.add(ch.nid)
        ordered.append(ch)
    return ordered


def _find_node(nid: str, store: dict) -> _ResNode | None:
    nmap = store["nodes"]
    if nid in nmap:
        return nmap[nid]
    return None


def _reach_order(start_id: str, store: dict, closure: bool) -> list[str]:
    claimed: dict[str, bool] = {}
    order: list[str] = []
    queue: deque[str] = deque([start_id])
    nodes = store["nodes"]
    while queue:
        nid = queue.popleft()
        if nid in claimed:
            continue
        claimed[nid] = True
        order.append(nid)
        nd = nodes.get(nid)
        if nd is not None:
            kids = _sorted_closure_out(nd) if closure else _sorted_tree_out(nd)
            for child in reversed(kids):
                queue.appendleft(child.nid)
    return order


def fresh_resource_store() -> dict:
    return {
        "nodes_map": {},
        "resources": {},
        "traits": {},
        "tree": {},
        "rev": {},
        "groups": {},
        "nodes": {},
        "roots": [],
    }


def register_resource(
    nid: str, resources: int, traits: str, store: dict | None = None
) -> dict:
    s = store
    if s is None:
        s = fresh_resource_store()
    s["nodes_map"][nid] = True
    s["resources"][nid] = resources
    s["traits"][nid] = traits
    tree = s["tree"]
    if nid not in tree:
        tree[nid] = []
    revs = s["rev"]
    if nid not in revs:
        revs[nid] = []
    grps = s["groups"]
    if nid not in grps:
        grps[nid] = []
    nd = _ResNode(nid=nid, resources=resources, traits=traits)
    s["roots"].append(nid)
    s["nodes"][nid] = nd
    return s


def add_tree_edge(parent_id: str, child_id: str, store: dict) -> None:
    nmap = store["nodes_map"]
    if parent_id not in nmap or child_id not in nmap:
        raise KeyError("unknown node id")
    if parent_id == child_id:
        return
    par_nd = _find_node(parent_id, store)
    ch_nd = _find_node(child_id, store)
    if par_nd is not None and ch_nd is not None:
        seen = any(ex.nid == child_id for ex in par_nd.tree_out)
        if not seen:
            par_nd.tree_out.append(ch_nd)
        roots = store["roots"]
        if child_id in roots:
            roots.remove(child_id)
    tree = store["tree"]
    if child_id not in tree[parent_id]:
        tree[parent_id].append(child_id)
        tree[parent_id] = sorted(tree[parent_id])
    revs = store["rev"]
    if parent_id not in revs[child_id]:
        revs[child_id].append(parent_id)
        revs[child_id] = sorted(revs[child_id])


def add_group_link(source_id: str, target_id: str, store: dict) -> None:
    nmap = store["nodes_map"]
    if source_id not in nmap or target_id not in nmap:
        raise KeyError("unknown node id")
    if source_id == target_id:
        return
    src_nd = _find_node(source_id, store)
    tgt_nd = _find_node(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.nid == target_id for ex in src_nd.group_out)
        if not seen:
            src_nd.group_out.append(tgt_nd)
    grps = store["groups"]
    if target_id not in grps[source_id]:
        grps[source_id].append(target_id)
        grps[source_id] = sorted(grps[source_id])


def direct_children(node_id: str, store: dict) -> list[str]:
    if node_id not in store["nodes_map"]:
        raise KeyError(node_id)
    return list(store["tree"].get(node_id, []))


def subtree_reach(start_id: str, store: dict) -> list[str]:
    if start_id not in store["nodes_map"]:
        raise KeyError(start_id)
    start_nd = _find_node(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for nid in _reach_order(start_id, store, closure=False):
        if nid != start_id:
            reach.append(nid)
    reach = sorted(reach)
    return reach


def closure_reach(start_id: str, store: dict) -> list[str]:
    if start_id not in store["nodes_map"]:
        raise KeyError(start_id)
    start_nd = _find_node(start_id, store)
    if start_nd is None:
        raise KeyError(start_id)
    reach: list[str] = []
    for nid in _reach_order(start_id, store, closure=True):
        if nid != start_id:
            reach.append(nid)
    reach = sorted(reach)
    return reach


def hierarchy_report(
    start_id: str, store: dict, min_resources: int, trait_need: str
) -> dict:
    if start_id not in store["nodes_map"]:
        raise KeyError(start_id)
    subtree = subtree_reach(start_id, store)
    closure = closure_reach(start_id, store)
    direct = direct_children(start_id, store)
    resources = store["resources"]
    traits = store["traits"]
    flat: list[str] = []
    for nid in sorted(store["nodes_map"].keys()):
        if resources.get(nid, 0) >= min_resources and traits.get(nid, "") == trait_need:
            flat.append(nid)
    sub_match: list[str] = []
    for nid in subtree:
        if resources.get(nid, 0) >= min_resources and traits.get(nid, "") == trait_need:
            sub_match.append(nid)
    sub_match = sorted(sub_match)
    return {
        "direct": direct,
        "subtree": subtree,
        "closure": closure,
        "flat_matches": flat,
        "subtree_matches": sub_match,
        "subtree_match_count": len(sub_match),
    }
