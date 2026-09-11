"""advplyr/audiobookshelf#5476 — paginated relational Collection read API."""

from __future__ import annotations

from collections import deque


class CollectionStore:
    def __init__(self) -> None:
        self.collections: dict[str, dict] = {}
        self.children_of: dict[str, list[str]] = {}
        self.books: dict[str, dict] = {}


def _coll_name_key(row: dict) -> str:
    return str(row["name"]).casefold()


def build_store(
    collection_rows: list[dict],
    book_rows: list[dict],
) -> CollectionStore:
    store = CollectionStore()
    for row in book_rows:
        store.books[str(row["id"])] = {
            "explicit": bool(row.get("explicit", False)),
            "tags": set(str(t) for t in row.get("tags", [])),
        }
    for row in collection_rows:
        cid = str(row["id"])
        store.collections[cid] = {
            "library_id": str(row["library_id"]),
            "name": str(row["name"]),
            "parent_id": row.get("parent_id"),
            "book_ids": [str(b) for b in row.get("books", [])],
        }
        store.children_of.setdefault(cid, [])
    for cid, col in store.collections.items():
        parent_id = col["parent_id"]
        if parent_id is not None and parent_id in store.collections:
            store.children_of.setdefault(str(parent_id), []).append(cid)
    return store


def _book_visible(
    book_id: str,
    store: CollectionStore,
    user_tags: set[str],
    allow_explicit: bool,
) -> bool:
    meta = store.books.get(book_id)
    if meta is None:
        return False
    if meta["explicit"] and not allow_explicit:
        return False
    if user_tags and not (meta["tags"] & user_tags):
        return False
    return True


def accessible_books(
    store: CollectionStore,
    collection_id: str,
    user_tags: set[str],
    allow_explicit: bool,
) -> list[str]:
    if collection_id not in store.collections:
        return []
    return sorted(
        bid
        for bid in store.collections[collection_id]["book_ids"]
        if _book_visible(bid, store, user_tags, allow_explicit)
    )


def ancestor_ids(store: CollectionStore, collection_id: str) -> list[str]:
    if collection_id not in store.collections:
        return []
    chain: list[str] = []
    cur = store.collections[collection_id]["parent_id"]
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(str(cur))
        nxt = store.collections.get(str(cur))
        if nxt is None:
            cur = None
        else:
            cur = nxt.get("parent_id")
    chain.reverse()
    return chain


def descendant_ids(store: CollectionStore, root_id: str) -> list[str]:
    if root_id not in store.collections:
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
        for child_id in sorted(store.children_of.get(cur, [])):
            if child_id not in seen:
                queue.append(child_id)
    return sorted(out)


def paginate_collections(
    store: CollectionStore,
    library_id: str,
    user_tags: set[str],
    allow_explicit: bool,
    *,
    page: int = 0,
    limit: int = 20,
    sort_key: str = "name",
    descending: bool = False,
    name_filter: str = "",
    preview_limit: int = 2,
) -> dict:
    needle = name_filter.casefold()
    rows: list[dict] = []
    for cid, col in store.collections.items():
        if col["library_id"] != library_id:
            continue
        if needle and needle not in str(col["name"]).casefold():
            continue
        visible = accessible_books(store, cid, user_tags, allow_explicit)
        rows.append({"name": str(col["name"]), "cid": cid, "visible": visible})
    if sort_key == "name":
        rows = sorted(rows, key=_coll_name_key, reverse=descending)
    else:
        rows = sorted(rows, key=_coll_name_key)
    start = page * limit
    end = start + limit
    page_rows = rows[start:end]
    results: list[dict] = []
    for row in page_rows:
        cid = str(row["cid"])
        visible = row["visible"]
        col = store.collections[cid]
        previews = [{"id": visible[j]} for j in range(min(preview_limit, len(visible)))]
        results.append(
            {
                "id": cid,
                "libraryId": col["library_id"],
                "name": str(row["name"]),
                "parentId": col.get("parent_id"),
                "numBooks": len(visible),
                "previewItems": previews,
            }
        )
    return {"total": len(rows), "results": results}
