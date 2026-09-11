"""RicoSuter/Namotion.Interceptor#410 — stranded fallback edges on partial detach."""

from collections import deque


class DelegationCycleError(Exception):
    """Pure delegator fallback cycle with no terminating service."""


def create_registry() -> dict:
    return {"subjects": {}, "fallbacks": {}, "services": {}, "props": {}}


def add_subject(reg: dict, subject_id: str, parent_id: str | None = None) -> None:
    reg["subjects"][subject_id] = {
        "parent": parent_id,
        "ref_count": 1,
        "prop_removed": False,
    }
    reg["fallbacks"].setdefault(subject_id, [])
    reg["services"].setdefault(subject_id, set())


def bind_property(reg: dict, owner_id: str, prop_name: str, target_id: str) -> None:
    reg["props"][(owner_id, prop_name)] = target_id
    adj = reg["fallbacks"].setdefault(owner_id, [])
    if target_id not in adj:
        adj.append(target_id)


def register_service(reg: dict, subject_id: str, service_name: str) -> None:
    reg["services"].setdefault(subject_id, set()).add(service_name)


def detach_subject(reg: dict, subject_id: str, property_removed: bool) -> None:
    sub = reg["subjects"][subject_id]
    sub["ref_count"] = 0
    if property_removed:
        sub["prop_removed"] = True
    if sub["ref_count"] == 0 and sub["prop_removed"]:
        _remove_inherited_fallbacks(reg, subject_id)


def _remove_inherited_fallbacks(reg: dict, subject_id: str) -> None:
    drop: set[str] = set()
    for (owner, _prop), tgt in reg["props"].items():
        if owner == subject_id:
            drop.add(tgt)
    reg["fallbacks"][subject_id] = [
        t for t in reg["fallbacks"].get(subject_id, []) if t not in drop
    ]


def list_fallback_edges(reg: dict) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    for src in sorted(reg["fallbacks"]):
        for tgt in sorted(reg["fallbacks"][src]):
            out.append((src, tgt))
    return out


def resolve_service(reg: dict, subject_id: str, service_name: str) -> str | None:
    visited: set[str] = set()
    on_path: set[str] = set()
    stack: list[tuple[str, int]] = [(subject_id, 0)]
    path: list[str] = []
    adj_stack: list[list[str]] = []
    # iterative DFS with path tracking to avoid diamond false cycle
    def _neighbors(cur: str) -> list[str]:
        return sorted(reg["fallbacks"].get(cur, []), reverse=True)
    cur = subject_id
    idx = 0
    neighbors = _neighbors(cur)
    path.append(cur)
    on_path.add(cur)
    visited.add(cur)
    if service_name in reg["services"].get(cur, set()):
        return cur
    adj_stack.append(neighbors)
    stack = [(cur, 0)]
    while stack:
        cur, i = stack[-1]
        neigh = adj_stack[-1]
        if i >= len(neigh):
            on_path.discard(cur)
            path.pop()
            stack.pop()
            adj_stack.pop()
            continue
        nxt = neigh[i]
        stack[-1] = (cur, i + 1)
        if nxt in on_path:
            if not reg["services"].get(nxt):
                raise DelegationCycleError(nxt)
            continue
        if nxt in visited:
            continue
        visited.add(nxt)
        on_path.add(nxt)
        path.append(nxt)
        if service_name in reg["services"].get(nxt, set()):
            return nxt
        adj_stack.append(_neighbors(nxt))
        stack.append((nxt, 0))
    return None


def delegation_cycle_nodes(reg: dict) -> list[str]:
    cyclic: set[str] = set()
    for start in sorted(reg["subjects"]):
        if reg["services"].get(start):
            continue
        stack: list[tuple[str, list[str], set[str]]] = [(start, [start], {start})]
        while stack:
            node, path, on_path = stack.pop()
            for nxt in sorted(reg["fallbacks"].get(node, [])):
                if nxt in on_path:
                    idx = path.index(nxt)
                    ring = path[idx:]
                    if all(not reg["services"].get(n) for n in ring):
                        cyclic.update(ring)
                else:
                    np = set(on_path)
                    np.add(nxt)
                    stack.append((nxt, path + [nxt], np))
    return sorted(cyclic)


def reachable_via_fallback(reg: dict, subject_id: str) -> list[str]:
    seen: set[str] = set()
    q: deque[str] = deque([subject_id])
    while q:
        u = q.popleft()
        if u in seen:
            continue
        seen.add(u)
        for v in sorted(reg["fallbacks"].get(u, [])):
            if v not in seen:
                q.append(v)
    seen.discard(subject_id)
    return sorted(seen)
