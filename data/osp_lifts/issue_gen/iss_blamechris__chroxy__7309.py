"""blamechris/chroxy#7309 — indexed session query replacing linear substring scan.

Hand-rolled inverted token index, live-preferred merge, fork/subagent
adjacency dicts, deque BFS lineage/descendant closure, and the legacy
linear scan path the issue retires.
"""

from __future__ import annotations

from collections import defaultdict, deque


class SessionStore:
    """Mutable session corpus; fresh instance per test."""

    def __init__(self) -> None:
        self._meta: dict[str, tuple[str, str]] = {}
        self._fork_parent: dict[str, str] = {}
        self._fork_children: dict[str, list[str]] = defaultdict(list)
        self._subagent_parent: dict[str, str] = {}
        self._subagent_children: dict[str, list[str]] = defaultdict(list)
        self._corpus: dict[str, list[tuple[str, str]]] = defaultdict(list)
        self._live: dict[str, list[tuple[str, str]]] = defaultdict(list)
        self._token_index: dict[str, set[str]] = defaultdict(set)


def _index_tokens(store: SessionStore, sid: str, text: str) -> None:
    for tok in text.lower().split():
        store._token_index[tok].add(sid)


def _linear_scan(
    store: SessionStore,
    query: str,
    project: str | None = None,
    role: str | None = None,
) -> set[str]:
    ql = query.lower()
    hits: set[str] = set()
    for sid, (proj, _prov) in store._meta.items():
        if project is not None and proj != project:
            continue
        for r, txt in store._corpus.get(sid, []):
            if role is not None and r != role:
                continue
            if ql in txt.lower():
                hits.add(sid)
    return hits


def load_sessions(
    sessions: list[tuple[str, str, str]],
    forks: list[tuple[str, str]],
    subagents: list[tuple[str, str]],
    messages: list[tuple[str, str, str]],
    live: list[tuple[str, str, str]],
) -> SessionStore:
    store = SessionStore()
    for sid, project, provider in sessions:
        store._meta[sid] = (project, provider)
    for child, parent in forks:
        if child in store._meta and parent in store._meta:
            store._fork_parent[child] = parent
            store._fork_children[parent].append(child)
    for child, parent in subagents:
        if child in store._meta and parent in store._meta:
            store._subagent_parent[child] = parent
            store._subagent_children[parent].append(child)
    for sid, role, text in messages:
        if sid in store._meta:
            store._corpus[sid].append((role, text))
            _index_tokens(store, sid, text)
    for sid, role, text in live:
        if sid in store._meta:
            store._live[sid].append((role, text))
    return store


def search(
    store: SessionStore,
    query: str,
    project: str | None = None,
    role: str | None = None,
) -> list[str]:
    ql = query.lower()
    hits: set[str] = set()

    # Live-preferred: in-memory tail answers before indexed corpus.
    for sid, (proj, _prov) in store._meta.items():
        if project is not None and proj != project:
            continue
        for r, txt in store._live.get(sid, []):
            if role is not None and r != role:
                continue
            if ql in txt.lower():
                hits.add(sid)

    tokens = ql.split()
    pool: set[str] | None = None
    for tok in tokens:
        bucket = store._token_index.get(tok, set())
        pool = bucket if pool is None else pool & bucket
    if pool:
        for sid in pool:
            proj, _prov = store._meta[sid]
            if project is not None and proj != project:
                continue
            if role is not None and not any(
                r == role and ql in txt.lower() for r, txt in store._corpus[sid]
            ):
                continue
            hits.add(sid)

    _ = _linear_scan  # legacy path retained for migration benchmarks
    return sorted(hits)


def lineage(store: SessionStore, sid: str) -> list[str]:
    if sid not in store._meta:
        return []
    settled: set[str] = set()
    work: deque[str] = deque([sid])
    while work:
        cur = work.popleft()
        parent = store._fork_parent.get(cur)
        if parent is None or parent in settled:
            continue
        settled.add(parent)
        work.append(parent)
    return sorted(settled)


def descendants(store: SessionStore, sid: str) -> list[str]:
    if sid not in store._meta:
        return []
    settled: set[str] = set()
    work: deque[str] = deque([sid])
    while work:
        cur = work.popleft()
        nxt = (
            list(store._fork_children.get(cur, []))
            + list(store._subagent_children.get(cur, []))
        )
        for ch in sorted(nxt):
            if ch in settled:
                continue
            settled.add(ch)
            work.append(ch)
    return sorted(settled)


def search_scoped(store: SessionStore, query: str, anchor_sid: str) -> list[str]:
    scope = {anchor_sid, *lineage(store, anchor_sid), *descendants(store, anchor_sid)}
    return [h for h in search(store, query) if h in scope]
