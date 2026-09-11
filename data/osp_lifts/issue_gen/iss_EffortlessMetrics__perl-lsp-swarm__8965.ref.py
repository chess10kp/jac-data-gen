"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__8965."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__8965.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
CLASSES = ["Base", "RoleA", "Child", "App", "Hub", "Left", "Right", "Leaf"]
EXTENDS = [("Child", "Base"), ("App", "Child"), ("Left", "Leaf"), ("Right", "Leaf"), ("Hub", "Left"), ("Hub", "Right")]
ROLES = [("App", "RoleA")]
CANONICAL = [
    ("Base", "attr:size"),
    ("Base", "gen:accessor"),
    ("RoleA", "gen:reader:tag"),
    ("Leaf", "fact:probe"),
]
DUPLICATE = [
    ("App", "attr:size", "canonical:Base"),
    ("App", "attr:size", "workspace_scan"),
    ("App", "attr:size", "semantic_extractor"),
    ("App", "gen:accessor", "canonical:Base"),
    ("App", "gen:accessor", "class_model_builder"),
    ("App", "gen:reader:tag", "canonical:RoleA"),
    ("App", "gen:reader:tag", "completion_reparse"),
    ("App", "missing:fact", "hover_special"),
    ("App", "missing:fact", "test_shadow_row"),
]
M = _mod.load_moo_model(CLASSES, EXTENDS, ROLES, CANONICAL, DUPLICATE)
DM = _mod.load_moo_model(CLASSES, EXTENDS, ROLES, CANONICAL, [])

assert _mod.upstream_lineage(M, "App") == ["Child", "Base"]
assert _mod.upstream_lineage(M, "Base") == []
assert _mod.upstream_lineage(M, "Ghost") == []

assert _mod.lineage_bfs_reach(M, "App") == ["Child", "RoleA", "Base"]
assert _mod.lineage_bfs_reach(M, "Ghost") == []
assert _mod.lineage_bfs_reach(M, "App", max_depth=1) == ["Child", "RoleA"]

assert _mod.fact_holder_paths(M, "App", "attr:size") == [["App", "Child", "Base"]]
assert _mod.fact_holder_paths(M, "App", "gen:reader:tag") == [["App", "RoleA"]]
assert _mod.fact_holder_paths(M, "App", "missing:fact") == []
assert _mod.fact_holder_paths(DM, "Hub", "fact:probe", max_depth=6) == [
    ["Hub", "Left", "Leaf"],
    ["Hub", "Right", "Leaf"],
]

assert _mod.cutover_route(
    has_canonical=True,
    shadow_ok=True,
    freshness_ok=True,
    semantic_ok=True,
    provider_ready=True,
) == "canonical"
assert _mod.cutover_route(
    has_canonical=True,
    shadow_ok=False,
    freshness_ok=True,
    semantic_ok=True,
    provider_ready=True,
) == "fallback"
assert _mod.cutover_route(
    has_canonical=False,
    shadow_ok=True,
    freshness_ok=True,
    semantic_ok=True,
    provider_ready=True,
) == "refusal"

assert _mod.duplicate_path_inventory(M, "App", "attr:size") == {
    "canonical:Base": "transferred_to_canonical_owner",
    "semantic_extractor": "removed_after_cutover",
    "workspace_scan": "removed_after_cutover",
}
assert _mod.duplicate_path_inventory(M, "App", "gen:reader:tag") == {
    "canonical:RoleA": "transferred_to_canonical_owner",
    "completion_reparse": "removed_after_cutover",
}
assert _mod.duplicate_path_inventory(M, "App", "missing:fact") == {
    "hover_special": "retained_bounded_fallback_for_named_unsupported_form",
    "test_shadow_row": "retained_standalone_test_only",
}
assert _mod.duplicate_path_inventory(M, "Ghost", "attr:size") == {}
print("iss_EffortlessMetrics__perl-lsp-swarm__8965 ref OK")
