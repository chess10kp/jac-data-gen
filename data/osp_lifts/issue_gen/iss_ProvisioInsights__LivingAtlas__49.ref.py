"""Reference harness for iss_ProvisioInsights__LivingAtlas__49."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_ProvisioInsights__LivingAtlas__49.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
ENTITIES = [
    {"id": "root", "tombstone": False, "access_class": "public", "content_hash": "h_root"},
    {"id": "ent_a", "tombstone": False, "access_class": "public", "content_hash": "h_a"},
    {"id": "ent_b", "tombstone": False, "access_class": "public", "content_hash": "h_b"},
    {"id": "ent_c", "tombstone": False, "access_class": "public", "content_hash": "h_c"},
    {"id": "ent_d", "tombstone": False, "access_class": "public", "content_hash": "h_d"},
    {"id": "tomb_ent", "tombstone": True, "access_class": "admin", "content_hash": "h_t"},
]
FACTS = [
    {"entity_id": "ent_a", "key": "kind", "value": "entity", "valid_at": "2024-01-01"},
    {"entity_id": "ent_b", "key": "kind", "value": "entity", "valid_at": "2024-01-02"},
    {"entity_id": "ent_b", "key": "label", "value": "beta", "valid_at": "2024-01-02"},
]
DEPENDS = [
    ("ent_d", "ent_c"),
    ("ent_d", "ent_b"),
    ("ent_c", "ent_a"),
    ("ent_b", "ent_a"),
    ("ent_a", "root"),
]
PARENTS = [
    ("ent_a", "root"),
    ("ent_b", "ent_a"),
    ("ent_c", "ent_a"),
    ("ent_d", "ent_b"),
]

graph = _mod.make_knowledge_graph(ENTITIES, FACTS, DEPENDS, PARENTS)

assert _mod.get_entity(graph, "ent_a") == {
    "id": "ent_a",
    "tombstone": False,
    "access_class": "public",
    "content_hash": "h_a",
}
assert _mod.get_entity(graph, "missing") is None

assert _mod.query_facts(graph, "ent_b") == [
    {"entity_id": "ent_b", "key": "kind", "value": "entity", "valid_at": "2024-01-02"},
    {"entity_id": "ent_b", "key": "label", "value": "beta", "valid_at": "2024-01-02"},
]
assert _mod.query_facts(graph, "missing") == []

assert _mod.upstream_dependencies(graph, "ent_d") == ["ent_a", "ent_b", "ent_c", "root"]
assert _mod.upstream_dependencies(graph, "ent_d", 1) == ["ent_b", "ent_c"]
assert _mod.upstream_dependencies(graph, "missing") == []

assert _mod.downstream_dependents(graph, "ent_a") == ["ent_b", "ent_c", "ent_d"]
assert _mod.downstream_dependents(graph, "root") == ["ent_a", "ent_b", "ent_c", "ent_d"]
assert _mod.downstream_dependents(graph, "missing") == []

assert _mod.depends_path(graph, "ent_d", "root") == ["ent_d", "ent_b", "ent_a", "root"]
assert _mod.depends_path(graph, "ent_d", "ent_a") == ["ent_d", "ent_b", "ent_a"]
assert _mod.depends_path(graph, "root", "ent_d") == []
assert _mod.depends_path(graph, "missing", "root") == []

assert _mod.lineage_to_root(graph, "ent_d") == ["ent_d", "ent_b", "ent_a", "root"]
assert _mod.lineage_to_root(graph, "root") == ["root"]
assert _mod.lineage_to_root(graph, "missing") == []

assert _mod.entity_counts(graph) == {"active": 5, "tombstone": 1, "total": 6}

bundle = _mod.canonical_export(graph)
assert bundle["version"] == "1"
assert bundle["depends"] == [
    ("ent_a", "root"),
    ("ent_b", "ent_a"),
    ("ent_c", "ent_a"),
    ("ent_d", "ent_b"),
    ("ent_d", "ent_c"),
]
assert bundle["parents"] == [
    ("ent_a", "root"),
    ("ent_b", "ent_a"),
    ("ent_c", "ent_a"),
    ("ent_d", "ent_b"),
]

restored = _mod.canonical_import(bundle)
assert _mod.upstream_dependencies(restored, "ent_d") == ["ent_a", "ent_b", "ent_c", "root"]
assert _mod.downstream_dependents(restored, "ent_a") == ["ent_b", "ent_c", "ent_d"]
assert _mod.depends_path(restored, "ent_d", "root") == ["ent_d", "ent_b", "ent_a", "root"]
assert _mod.lineage_to_root(restored, "ent_d") == ["ent_d", "ent_b", "ent_a", "root"]
assert _mod.entity_counts(restored) == {"active": 5, "tombstone": 1, "total": 6}

try:
    _mod.canonical_import({"version": "9"})
    raise AssertionError("expected ValueError")
except ValueError:
    pass
print("iss_ProvisioInsights__LivingAtlas__49 ref OK")
