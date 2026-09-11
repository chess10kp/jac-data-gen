"""advplyr/audiobookshelf#5452 — nested collection parentId hierarchy."""

from __future__ import annotations

from collections import deque


class CollectionLibrary:
    def __init__(self) -> None:
        self.collections: dict[str, dict] = {}
        self.children_of: dict[str, list[str]] = {}


def load_collection_library(records: list[dict]) -> CollectionLibrary:
    lib = CollectionLibrary()
    for rec in records:
        cid = rec["id"]
        lib.collections[cid] = {
            "library_id": rec["library_id"],
            "name": rec["name"],
            "parent_id": rec.get("parent_id"),
            "books": list(rec.get("books", [])),
        }
        lib.children_of.setdefault(cid, [])
    for cid, row in lib.collections.items():
        parent_id = row["parent_id"]
        if parent_id is not None and parent_id in lib.collections:
            lib.children_of.setdefault(parent_id, []).append(cid)
    return lib


def list_root_collections(lib: CollectionLibrary, library_id: str) -> list[str]:
    return sorted(
        cid
        for cid, row in lib.collections.items()
        if row["library_id"] == library_id and row["parent_id"] is None
    )


def child_collections(lib: CollectionLibrary, parent_id: str) -> list[str]:
    if parent_id not in lib.collections:
        return []
    return sorted(lib.children_of.get(parent_id, []))


def breadcrumb(lib: CollectionLibrary, collection_id: str) -> list[str]:
    if collection_id not in lib.collections:
        return []
    chain: list[str] = []
    cur: str | None = collection_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(lib.collections[cur]["name"])
        cur = lib.collections[cur]["parent_id"]
    chain.reverse()
    return chain


def descendant_collections(lib: CollectionLibrary, root_id: str) -> list[str]:
    if root_id not in lib.collections:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([root_id])
    out: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != root_id:
            out.append(cur)
        for child_id in sorted(lib.children_of.get(cur, [])):
            if child_id not in seen:
                queue.append(child_id)
    return sorted(out)


def would_create_cycle(
    lib: CollectionLibrary, child_id: str, new_parent_id: str
) -> bool:
    if child_id not in lib.collections or new_parent_id not in lib.collections:
        return False
    if child_id == new_parent_id:
        return True
    cur: str | None = new_parent_id
    seen: set[str] = set()
    while cur is not None:
        if cur == child_id:
            return True
        if cur in seen:
            return True
        seen.add(cur)
        cur = lib.collections[cur]["parent_id"]
    return False


def set_parent(
    lib: CollectionLibrary, child_id: str, parent_id: str | None
) -> None:
    if child_id not in lib.collections:
        raise KeyError(child_id)
    if parent_id is not None:
        if parent_id not in lib.collections:
            raise KeyError(parent_id)
        if child_id == parent_id:
            raise ValueError("collection cannot be its own parent")
        child_lib = lib.collections[child_id]["library_id"]
        parent_lib = lib.collections[parent_id]["library_id"]
        if child_lib != parent_lib:
            raise ValueError("parent and child must belong to the same library")
        if would_create_cycle(lib, child_id, parent_id):
            raise ValueError("parent assignment would create cycle")
    old_parent = lib.collections[child_id]["parent_id"]
    if old_parent is not None:
        siblings = lib.children_of.get(old_parent, [])
        lib.children_of[old_parent] = [c for c in siblings if c != child_id]
    lib.collections[child_id]["parent_id"] = parent_id
    if parent_id is not None:
        lib.children_of.setdefault(parent_id, []).append(child_id)


def delete_collection(lib: CollectionLibrary, collection_id: str) -> list[str]:
    if collection_id not in lib.collections:
        raise KeyError(collection_id)
    reparented: list[str] = []
    for child_id in list(lib.children_of.get(collection_id, [])):
        lib.collections[child_id]["parent_id"] = None
        reparented.append(child_id)
    old_parent = lib.collections[collection_id]["parent_id"]
    if old_parent is not None:
        siblings = lib.children_of.get(old_parent, [])
        lib.children_of[old_parent] = [c for c in siblings if c != collection_id]
    del lib.collections[collection_id]
    del lib.children_of[collection_id]
    return sorted(reparented)
