"""Shyden-Ltd/ShyTalk#1963 — resolved cohort never recomputed after date-of-birth gate.

Profile fields form a dependency lineage: date_of_birth feeds effective_cohort,
which feeds resolved_cohort and the session cache. Hand-rolled adjacency dicts,
deque BFS, parent-trail reconstruction, and Kahn ordering stand in for the
AuthViewModel resolve path.
"""

from __future__ import annotations

from collections import defaultdict, deque


class ProfileStore:
    def __init__(self) -> None:
        self.dep_fwd: dict[str, list[str]] = defaultdict(list)
        self.dep_rev: dict[str, list[str]] = defaultdict(list)
        self.users: dict[str, dict] = {}
        self.values: dict[str, dict[str, str | None]] = defaultdict(dict)
        self.session_cache: dict[str, str | None] = {}


def load_profile_store(
    users: dict[str, dict],
    depends: list[tuple[str, str]],
) -> ProfileStore:
    store = ProfileStore()
    store.users = {uid: dict(profile) for uid, profile in users.items()}
    for dependent, source in depends:
        if source not in store.dep_fwd[dependent]:
            store.dep_fwd[dependent].append(source)
        if dependent not in store.dep_rev[source]:
            store.dep_rev[source].append(dependent)
    return store


def downstream_fields(store: ProfileStore, field: str) -> list[str]:
    known = set(store.dep_fwd) | set(store.dep_rev)
    if field not in known:
        return []
    claimed: set[str] = set()
    work: deque[str] = deque([field])
    hits: set[str] = set()
    while work:
        cur = work.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        for nxt in sorted(store.dep_rev.get(cur, [])):
            if nxt not in claimed:
                work.append(nxt)
            if nxt != field:
                hits.add(nxt)
    return sorted(hits)


def depends_path(store: ProfileStore, src: str, dst: str) -> list[str]:
    known = set(store.dep_fwd) | set(store.dep_rev)
    if src not in known or dst not in known:
        return []
    parent: dict[str, str | None] = {src: None}
    work: deque[str] = deque([src])
    while work:
        cur = work.popleft()
        if cur == dst:
            trail: list[str] = []
            node: str | None = dst
            while node is not None:
                trail.append(node)
                node = parent[node]
            return list(reversed(trail))
        for nxt in sorted(store.dep_rev.get(cur, [])):
            if nxt not in parent:
                parent[nxt] = cur
                work.append(nxt)
    return []


def invalidation_order(store: ProfileStore, changed: str) -> list[str]:
    targets: set[str] = set()
    claimed: set[str] = set()
    work: deque[str] = deque([changed])
    while work:
        cur = work.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        for nxt in store.dep_rev.get(cur, []):
            targets.add(nxt)
            work.append(nxt)
    if not targets:
        return []
    indeg: dict[str, int] = {t: 0 for t in targets}
    for t in targets:
        for src in store.dep_fwd.get(t, []):
            if src in targets:
                indeg[t] += 1
    q: deque[str] = deque(sorted(t for t in targets if indeg[t] == 0))
    order: list[str] = []
    while q:
        cur = q.popleft()
        order.append(cur)
        for nxt in sorted(store.dep_rev.get(cur, [])):
            if nxt not in targets:
                continue
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)
    return order


def effective_cohort(dob_year: int | None, ref_year: int = 2026) -> str | None:
    if dob_year is None:
        return "minor"
    if ref_year - dob_year < 18:
        return "minor"
    return "adult"


def resolve_profile_state(store: ProfileStore, uid: str, ref_year: int = 2026) -> str | None:
    if uid not in store.users:
        return None
    dob = store.users[uid].get("date_of_birth")
    eff = effective_cohort(dob, ref_year)
    store.values[uid]["effective_cohort"] = eff
    store.values[uid]["resolved_cohort"] = eff
    store.session_cache[uid] = eff
    store.values[uid]["session_cache"] = eff
    return eff


def complete_dob_gate(
    store: ProfileStore,
    uid: str,
    dob_year: int,
    ref_year: int = 2026,
    *,
    refresh_ok: bool = True,
) -> str | None:
    if uid not in store.users:
        return None
    store.users[uid]["date_of_birth"] = dob_year
    if not refresh_ok:
        store.values[uid]["resolved_cohort"] = None
        store.values[uid]["session_cache"] = None
        store.session_cache[uid] = None
        return None
    for field in invalidation_order(store, "date_of_birth"):
        if field == "effective_cohort":
            val = effective_cohort(dob_year, ref_year)
        elif field == "resolved_cohort":
            val = store.values[uid].get("effective_cohort")
        elif field == "session_cache":
            val = store.values[uid].get("resolved_cohort")
        else:
            val = store.values[uid].get(field)
        store.values[uid][field] = val
        if field == "session_cache":
            store.session_cache[uid] = val
    return store.values[uid].get("resolved_cohort")


def read_resolved_cohort(store: ProfileStore, uid: str) -> str | None:
    return store.values.get(uid, {}).get("resolved_cohort")


def session_cache_cohort(store: ProfileStore, uid: str) -> str | None:
    return store.session_cache.get(uid)
