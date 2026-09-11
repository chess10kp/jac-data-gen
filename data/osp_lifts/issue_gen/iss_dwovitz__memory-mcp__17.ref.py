import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_dwovitz__memory-mcp__17.py"
_spec = importlib.util.spec_from_file_location("memmcp_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
build_memory_graph = _mod.build_memory_graph
get_graph_context = _mod.get_graph_context
resolve_seeds = _mod.resolve_seeds

ENTITIES = [
    ("e_darkfactory", "dark-factory", ["DF", "dark factory"], False),
    ("e_quota", "quota-policy", [], False),
    ("e_router", "model-routing", ["routing"], False),
    ("e_judge", "review-judges", [], False),
    ("e_priv", "private-notes", ["notes"], True),
]
RELS = [
    ("e_darkfactory", "e_quota", "governed_by"),
    ("e_darkfactory", "e_router", "uses"),
    ("e_router", "e_judge", "reviewed_by"),
    ("e_darkfactory", "e_priv", "documents"),
]
MEMORIES = [
    ("m1", "e_darkfactory", "timeout pattern: raise worker grace to 30s"),
    ("m2", "e_quota", "daily quota resets at 00:00 UTC"),
    ("m3", "e_router", "route vision models to fallback pool"),
    ("m4", "e_judge", "judge rubric v3 weights safety highest"),
    ("m5", "e_priv", "personal api key rotation note"),
]

g = build_memory_graph(ENTITIES, RELS, MEMORIES)

# Alias and name resolution collapse onto canonical ids.
assert resolve_seeds(g, ["DF", "dark-factory"]) == ["e_darkfactory"]
assert resolve_seeds(g, ["routing", "review-judges"]) == ["e_judge", "e_router"]
assert resolve_seeds(g, ["nope"]) == []

# Bounded traversal: depth 2 from dark-factory; sensitive e_priv contributes
# nothing (not reached, not expanded), so 4 entity ids come back.
ids, texts = get_graph_context(g, ["e_darkfactory"], max_depth=2, max_memories=10)
assert len(ids) == 4
assert "e_priv" not in ids
assert "timeout pattern: raise worker grace to 30s" in texts

# Depth 0 sees only the seed entity's own memories.
ids0, texts0 = get_graph_context(g, ["e_darkfactory"], max_depth=0)
assert ids0 == ["e_darkfactory"]
assert texts0 == ["timeout pattern: raise worker grace to 30s"]

# Memory cap enforces the token budget.
_, capped = get_graph_context(g, ["e_darkfactory"], max_depth=2, max_memories=2)
assert len(capped) == 2

# Sensitive entities are excluded unless explicitly allowed.
ids_s, _ = get_graph_context(g, ["e_darkfactory"], max_depth=2)
assert "e_priv" not in ids_s
assert all("api key" not in t for t in
           get_graph_context(g, ["e_darkfactory"], max_depth=2)[1])
ids_o, _ = get_graph_context(g, ["e_darkfactory"], max_depth=2,
                             include_sensitive=True)
assert "e_priv" in ids_o

# Unknown seeds yield an empty packet.
assert get_graph_context(g, ["ghost"], max_depth=3) == ([], [])

print("memory-mcp 17 ref OK")
