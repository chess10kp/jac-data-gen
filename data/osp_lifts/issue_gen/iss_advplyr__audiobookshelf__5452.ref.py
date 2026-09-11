"""Reference harness for iss_advplyr__audiobookshelf__5452."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_advplyr__audiobookshelf__5452.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
LIB = _mod.load_collection_library(
    [
        {
            "id": "dnd",
            "library_id": "main",
            "name": "Dungeons & Dragons",
            "parent_id": None,
            "books": ["dmg", "mm", "phb"],
        },
        {
            "id": "adv",
            "library_id": "main",
            "name": "Adventures",
            "parent_id": "dnd",
            "books": ["adv1", "adv2"],
        },
        {
            "id": "exp",
            "library_id": "main",
            "name": "Expansions",
            "parent_id": "dnd",
            "books": ["exp1"],
        },
        {
            "id": "sw",
            "library_id": "main",
            "name": "Star Wars",
            "parent_id": None,
            "books": [],
        },
        {
            "id": "canon",
            "library_id": "main",
            "name": "Canon",
            "parent_id": "sw",
            "books": [],
        },
        {
            "id": "hr",
            "library_id": "main",
            "name": "High Republic",
            "parent_id": "canon",
            "books": ["hr1"],
        },
        {
            "id": "nr",
            "library_id": "main",
            "name": "New Republic",
            "parent_id": "canon",
            "books": [],
        },
        {
            "id": "legends",
            "library_id": "main",
            "name": "Legends",
            "parent_id": "sw",
            "books": ["l1"],
        },
        {
            "id": "other",
            "library_id": "other_lib",
            "name": "Other",
            "parent_id": None,
            "books": [],
        },
    ]
)

assert _mod.list_root_collections(LIB, "main") == ["dnd", "sw"]
assert _mod.list_root_collections(LIB, "other_lib") == ["other"]
assert _mod.list_root_collections(LIB, "missing") == []

assert _mod.child_collections(LIB, "dnd") == ["adv", "exp"]
assert _mod.child_collections(LIB, "canon") == ["hr", "nr"]
assert _mod.child_collections(LIB, "missing") == []

assert _mod.breadcrumb(LIB, "hr") == [
    "Star Wars",
    "Canon",
    "High Republic",
]
assert _mod.breadcrumb(LIB, "dnd") == ["Dungeons & Dragons"]
assert _mod.breadcrumb(LIB, "missing") == []

assert _mod.descendant_collections(LIB, "sw") == [
    "canon",
    "hr",
    "legends",
    "nr",
]
assert _mod.descendant_collections(LIB, "dnd") == ["adv", "exp"]
assert _mod.descendant_collections(LIB, "missing") == []

assert _mod.would_create_cycle(LIB, "dnd", "adv") is True
assert _mod.would_create_cycle(LIB, "adv", "exp") is False
assert _mod.would_create_cycle(LIB, "dnd", "missing") is False

_mod.set_parent(LIB, "exp", "sw")
assert _mod.child_collections(LIB, "sw") == ["canon", "exp", "legends"]
assert _mod.child_collections(LIB, "dnd") == ["adv"]
assert _mod.breadcrumb(LIB, "exp") == ["Star Wars", "Expansions"]

try:
    _mod.set_parent(LIB, "adv", "other")
except ValueError as err:
    assert "same library" in str(err)
else:
    raise AssertionError("expected ValueError for cross-library parent")

try:
    _mod.set_parent(LIB, "adv", "adv")
except ValueError as err:
    assert "its own parent" in str(err)
else:
    raise AssertionError("expected ValueError for self-parent")

try:
    _mod.set_parent(LIB, "sw", "hr")
except ValueError as err:
    assert "create cycle" in str(err)
else:
    raise AssertionError("expected ValueError for cycle")

try:
    _mod.set_parent(LIB, "ghost", "sw")
except KeyError as err:
    assert str(err) == "'ghost'"
else:
    raise AssertionError("expected KeyError for unknown child")

assert _mod.delete_collection(LIB, "dnd") == ["adv"]
assert "dnd" not in LIB.collections
assert LIB.collections["adv"]["parent_id"] is None
assert _mod.list_root_collections(LIB, "main") == ["adv", "sw"]

try:
    _mod.delete_collection(LIB, "gone")
except KeyError as err:
    assert str(err) == "'gone'"
else:
    raise AssertionError("expected KeyError for unknown delete")
print("iss_advplyr__audiobookshelf__5452 ref OK")
