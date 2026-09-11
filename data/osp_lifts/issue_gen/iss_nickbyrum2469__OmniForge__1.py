"""nickbyrum2469/OmniForge#1 — Safe imported-asset deletion with usage cascade."""

from __future__ import annotations

from collections import deque


class AssetStore:
    def __init__(self) -> None:
        self._assets: set[str] = set()
        self._derivatives: dict[str, list[str]] = {}
        self._scene_refs: dict[str, list[str]] = {}


def load_asset_store(
    assets: list[str],
    derivative_edges: list[tuple[str, str]],
    scene_refs: list[tuple[str, str]],
) -> AssetStore:
    s = AssetStore()
    for aid in assets:
        s._assets.add(aid)
        s._derivatives.setdefault(aid, [])
        s._scene_refs.setdefault(aid, [])
    for parent, child in derivative_edges:
        if parent not in s._assets or child not in s._assets:
            continue
        s._derivatives[parent].append(child)
    for scene, asset in scene_refs:
        if asset not in s._assets:
            continue
        s._scene_refs[asset].append(scene)
    return s


def scene_usages(store: AssetStore, asset_id: str) -> list[str]:
    if asset_id not in store._assets:
        return []
    return sorted(set(store._scene_refs.get(asset_id, [])))


def _collect_derivatives(store: AssetStore, root: str) -> list[str]:
    seen: set[str] = set()
    stack = [root]
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in sorted(store._derivatives.get(cur, [])):
            if ch not in seen:
                stack.append(ch)
    return out


def delete_import(store: AssetStore, asset_id: str, force: bool = False) -> list[str]:
    if asset_id not in store._assets:
        return []
    if store._scene_refs.get(asset_id) and not force:
        raise ValueError("asset still referenced by scene")
    doomed = _collect_derivatives(store, asset_id)
    deleted = sorted(doomed)
    for aid in deleted:
        store._assets.discard(aid)
        store._derivatives.pop(aid, None)
        store._scene_refs.pop(aid, None)
        for refs in store._scene_refs.values():
            if aid in refs:
                refs.remove(aid)
        for kids in store._derivatives.values():
            if aid in kids:
                kids.remove(aid)
    return deleted


def active_assets(store: AssetStore) -> list[str]:
    return sorted(store._assets)
