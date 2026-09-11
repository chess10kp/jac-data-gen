"""Dependency-aware DAPS metadata cache with hand-rolled closure walks.

openSUSE/docbuild#447
"""

from __future__ import annotations

from collections import deque


def make_store(
    includes: list[tuple[str, str]],
    fingerprints: dict[str, str],
    records: dict[str, dict] | None = None,
) -> dict:
    adj: dict[str, list[str]] = {}
    for parent, child in includes:
        adj.setdefault(parent, [])
        adj.setdefault(child, [])
        if child not in adj[parent]:
            adj[parent].append(child)
    for node in fingerprints:
        adj.setdefault(node, [])
    return {
        "adj": adj,
        "fingerprints": dict(fingerprints),
        "records": dict(records or {}),
        "_memo": {},
    }


def transitive_deps(store: dict, deliverable_id: str) -> list[str]:
    memo = store["_memo"]
    if deliverable_id in memo:
        return list(memo[deliverable_id])
    adj = store["adj"]
    if deliverable_id not in adj:
        memo[deliverable_id] = []
        return []
    seen: set[str] = set()
    parent: dict[str, str | None] = {deliverable_id: None}
    q: deque[str] = deque([deliverable_id])
    seen.add(deliverable_id)
    while q:
        node = q.popleft()
        for dep in sorted(adj.get(node, [])):
            if dep not in seen:
                seen.add(dep)
                parent[dep] = node
                q.append(dep)
    out = sorted(seen - {deliverable_id})
    memo[deliverable_id] = out
    return list(out)


def dependency_fingerprint(store: dict, deliverable_id: str) -> str:
    deps = transitive_deps(store, deliverable_id)
    parts = sorted(
        f"{path}:{store['fingerprints'][path]}"
        for path in deps
        if path in store["fingerprints"]
    )
    return "|".join(parts)


def get_cached_metadata(store: dict, deliverable_id: str) -> dict | None:
    rec = store["records"].get(deliverable_id)
    if rec is None:
        return None
    if rec.get("fingerprint") != dependency_fingerprint(store, deliverable_id):
        return None
    return dict(rec["metadata"])


def resolve_metadata(store: dict, deliverable_id: str, runner) -> dict:
    if deliverable_id not in store["adj"]:
        raise KeyError(deliverable_id)
    fp = dependency_fingerprint(store, deliverable_id)
    rec = store["records"].get(deliverable_id)
    if rec is not None and rec.get("fingerprint") == fp:
        return dict(rec["metadata"])
    meta = runner(deliverable_id)
    deps = transitive_deps(store, deliverable_id)
    fp = dependency_fingerprint(store, deliverable_id)
    store["records"][deliverable_id] = {
        "metadata": dict(meta),
        "deps": list(deps),
        "fingerprint": fp,
    }
    return dict(meta)


def list_deliverables(store: dict) -> list[str]:
    return sorted(store["records"].keys())


def invalidate_cache(store: dict, deliverable_id: str) -> bool:
    if deliverable_id not in store["records"]:
        return False
    del store["records"][deliverable_id]
    store["_memo"].pop(deliverable_id, None)
    return True
