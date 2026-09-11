"""gyrinx-app/gyrinx#839 — batch equipment category restriction filtering."""

from __future__ import annotations

from collections import deque


class _CatNode:
    __slots__ = ("cid", "name", "out", "restricts")

    def __init__(self, cid: str, name: str) -> None:
        self.cid = cid
        self.name = name
        self.out: list[_CatNode] = []
        self.restricts: set[str] = set()


class _FighterNode:
    __slots__ = ("fid",)

    def __init__(self, fid: str) -> None:
        self.fid = fid


def _sorted_out(nd: _CatNode) -> list[_CatNode]:
    kids = list(nd.out)
    kids.sort(key=lambda ch: ch.cid)
    return kids


def _find_category(cid: str, store: dict) -> _CatNode | None:
    nmap = store["nodes"]
    if cid in nmap:
        return nmap[cid]
    return None


def _find_fighter(fid: str, store: dict) -> _FighterNode | None:
    fmap = store["fighters"]
    if fid in fmap:
        return fmap[fid]
    return None


def _restrict_walk(start_id: str, target_fid: str, store: dict) -> list[str]:
    claimed: dict[str, bool] = {}
    restricted: list[str] = []
    queue: deque[str] = deque([start_id])
    while queue:
        cid = queue.popleft()
        if cid in claimed:
            continue
        claimed[cid] = True
        nd = _find_category(cid, store)
        if nd is None:
            continue
        if target_fid in nd.restricts:
            restricted.append(cid)
        for child in reversed(_sorted_out(nd)):
            queue.appendleft(child.cid)
    return restricted


def fresh_gear_store() -> dict:
    return {"categories": {}, "fighters": {}, "deps": {}, "nodes": {}, "roots": []}


def register_category(cat_id: str, name: str, store: dict | None = None) -> dict:
    s = store
    if s is None:
        s = fresh_gear_store()
    s["categories"][cat_id] = name
    deps = s["deps"]
    if cat_id not in deps:
        deps[cat_id] = []
    nd = _CatNode(cid=cat_id, name=name)
    s["roots"].append(cat_id)
    s["nodes"][cat_id] = nd
    return s


def register_fighter_category(fid: str, store: dict) -> dict:
    if fid in store["fighters"]:
        return store
    store["fighters"][fid] = _FighterNode(fid=fid)
    return store


def add_cat_child(source_id: str, target_id: str, store: dict) -> None:
    cmap = store["categories"]
    if source_id not in cmap or target_id not in cmap:
        raise KeyError("unknown category id")
    if source_id == target_id:
        return
    src_nd = _find_category(source_id, store)
    tgt_nd = _find_category(target_id, store)
    if src_nd is not None and tgt_nd is not None:
        seen = any(ex.cid == target_id for ex in src_nd.out)
        if not seen:
            src_nd.out.append(tgt_nd)
        roots = store["roots"]
        if target_id in roots:
            roots.remove(target_id)
    outs = store["deps"]
    if source_id not in outs:
        outs[source_id] = []
    if target_id not in outs[source_id]:
        outs[source_id].append(target_id)
        outs[source_id] = sorted(outs[source_id])


def add_fighter_restriction(cat_id: str, fighter_cat_id: str, store: dict) -> None:
    if cat_id not in store["categories"]:
        raise KeyError(cat_id)
    register_fighter_category(fighter_cat_id, store)
    cat_nd = _find_category(cat_id, store)
    if cat_nd is not None:
        cat_nd.restricts.add(fighter_cat_id)


def prefetch_restricted_ids(fighter_cat_id: str, store: dict) -> list[str]:
    register_fighter_category(fighter_cat_id, store)
    restricted: list[str] = []
    roots = store["roots"]
    for rid in sorted(roots):
        nd = _find_category(rid, store)
        if nd is None:
            continue
        for cid in _restrict_walk(rid, fighter_cat_id, store):
            if cid not in restricted:
                restricted.append(cid)
    restricted = sorted(restricted)
    return restricted


def restricted_category_ids(fighter_cat_id: str, cat_ids: list[str], store: dict) -> list[str]:
    cmap = store["categories"]
    for cid in cat_ids:
        if cid not in cmap:
            raise KeyError(cid)
    pref = prefetch_restricted_ids(fighter_cat_id, store)
    blocked: list[str] = []
    for cid in cat_ids:
        if cid in pref:
            blocked.append(cid)
    blocked = sorted(blocked)
    return blocked


def restriction_report(fighter_cat_id: str, cat_ids: list[str], store: dict) -> dict:
    blocked = restricted_category_ids(fighter_cat_id, cat_ids, store)
    pref = prefetch_restricted_ids(fighter_cat_id, store)
    allowed: list[str] = []
    for cid in cat_ids:
        if cid not in blocked:
            allowed.append(cid)
    allowed = sorted(allowed)
    return {
        "blocked": blocked,
        "allowed": allowed,
        "prefetch_count": len(pref),
        "query_count": 1,
    }
