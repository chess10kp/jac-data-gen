"""Reference harness for iss_advplyr__audiobookshelf__5476."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_advplyr__audiobookshelf__5476.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
fantasy = {"fantasy"}
scifi = {"scifi"}

store = _mod.build_store(
    [
        {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": ["b1", "b2", "b3"]},
        {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": ["b5"]},
        {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": ["b6"]},
    ],
    [
        {"id": "b1", "explicit": False, "tags": ["fantasy"]},
        {"id": "b2", "explicit": False, "tags": ["fantasy", "core"]},
        {"id": "b3", "explicit": True, "tags": ["fantasy"]},
        {"id": "b5", "explicit": True, "tags": ["scifi"]},
        {"id": "b6", "explicit": False, "tags": ["scifi"]},
    ],
)
assert _mod.accessible_books(store, "dnd", fantasy, False) == ["b1", "b2"]
assert _mod.accessible_books(store, "dnd", fantasy, True) == ["b1", "b2", "b3"]
assert _mod.accessible_books(store, "sw", scifi, False) == []
assert _mod.accessible_books(store, "canon", scifi, False) == ["b6"]
assert _mod.accessible_books(store, "missing", fantasy, False) == []

store = _mod.build_store(
    [
        {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": []},
        {"id": "adv", "library_id": "main", "name": "Adventures", "parent_id": "dnd", "books": []},
        {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": []},
        {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": []},
    ],
    [],
)
assert _mod.ancestor_ids(store, "canon") == ["sw"]
assert _mod.ancestor_ids(store, "adv") == ["dnd"]
assert _mod.ancestor_ids(store, "dnd") == []
assert _mod.descendant_ids(store, "sw") == ["canon"]
assert _mod.descendant_ids(store, "dnd") == ["adv"]
assert _mod.ancestor_ids(store, "missing") == []
assert _mod.descendant_ids(store, "missing") == []

store = _mod.build_store(
    [
        {"id": "dnd", "library_id": "main", "name": "Dungeons & Dragons", "parent_id": None, "books": ["b1", "b2", "b3"]},
        {"id": "adv", "library_id": "main", "name": "Adventures", "parent_id": "dnd", "books": ["b4"]},
        {"id": "sw", "library_id": "main", "name": "Star Wars", "parent_id": None, "books": ["b5"]},
        {"id": "canon", "library_id": "main", "name": "Canon", "parent_id": "sw", "books": ["b6"]},
    ],
    [
        {"id": "b1", "explicit": False, "tags": ["fantasy"]},
        {"id": "b2", "explicit": False, "tags": ["fantasy"]},
        {"id": "b3", "explicit": True, "tags": ["fantasy"]},
        {"id": "b4", "explicit": False, "tags": ["fantasy"]},
        {"id": "b5", "explicit": True, "tags": ["scifi"]},
        {"id": "b6", "explicit": False, "tags": ["scifi"]},
    ],
)
page0 = _mod.paginate_collections(store, "main", fantasy, False, page=0, limit=2, preview_limit=2)
assert page0["total"] == 4
assert [row["id"] for row in page0["results"]] == ["adv", "canon"]
assert page0["results"][0]["previewItems"] == [{"id": "b4"}]
page1 = _mod.paginate_collections(store, "main", fantasy, False, page=1, limit=2, preview_limit=2)
assert [row["id"] for row in page1["results"]] == ["dnd", "sw"]
assert page1["results"][0]["previewItems"] == [{"id": "b1"}, {"id": "b2"}]
filtered = _mod.paginate_collections(store, "main", scifi, False, name_filter="can", preview_limit=1)
assert filtered["total"] == 1
assert [row["id"] for row in filtered["results"]] == ["canon"]
desc = _mod.paginate_collections(store, "main", fantasy, False, descending=True, preview_limit=1)
assert [row["name"] for row in desc["results"]] == [
    "Star Wars",
    "Dungeons & Dragons",
    "Canon",
    "Adventures",
]

store = _mod.build_store([], [])
assert _mod.paginate_collections(store, "missing", fantasy, False) == {"total": 0, "results": []}

cyc = _mod.build_store(
    [
        {"id": "c", "library_id": "cyc", "name": "C", "parent_id": "b", "books": []},
        {"id": "a", "library_id": "cyc", "name": "A", "parent_id": "c", "books": []},
        {"id": "b", "library_id": "cyc", "name": "B", "parent_id": "a", "books": []},
    ],
    [],
)
assert _mod.descendant_ids(cyc, "a") == ["b", "c"]
assert _mod.ancestor_ids(cyc, "b") == ["b", "c", "a"]
print("iss_advplyr__audiobookshelf__5476 ref OK")
