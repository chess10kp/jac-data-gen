"""Reference harness: exercises every public function of iss_ynput__ayon-backend__1018."""
import importlib

mod = importlib.import_module("iss_ynput__ayon-backend__1018")
EntityIndex = mod.EntityIndex

ix = EntityIndex()
ix.add_folder("project", None, {"fps": 25})
ix.add_folder("assets", "project", {"atlas": True})
ix.add_folder("shots", "project")
ix.add_folder("shot010", "shots", {"frame_start": 1001})
ix.add_folder("shot020", "shots")

# Canonical path built from the ancestor chain.
assert ix.canonical_path("shot010") == "project/shots/shot010"
assert ix.canonical_path("assets") == "project/assets"
assert ix.canonical_path("project") == "project"

# Subtree listing is a multiset (sorted).
assert ix.subtree_folders("project") == ["assets", "project", "shot010", "shot020", "shots"]
assert ix.subtree_folders("shot010") == ["shot010"]

# Inherited attributes: nearest ancestor wins, missing stays None.
assert ix.inherited_attribute("shot010", "frame_start") == 1001
assert ix.inherited_attribute("shot020", "fps") == 25       # from root
assert ix.inherited_attribute("assets", "atlas") is True    # self value
assert ix.inherited_attribute("shots", "atlas") is None     # sibling scope

# Cross-type chains: folder -> tasks -> products -> versions.
ix.attach_chain(task="t_comp", folder="shot010")
ix.attach_chain(task="t_layout", folder="shot010")
ix.attach_chain(task="t_model", folder="assets")
ix.attach_chain(product=("p_render", "t_comp"))
ix.attach_chain(product=("p_cache", "t_layout"))
ix.attach_chain(version=("v001", "p_render"))
ix.attach_chain(version=("v002", "p_render"))
ix.attach_chain(version=("v003", "p_cache"))

assert ix.versions_in_subtree("shot010") == ["v001", "v002", "v003"]
assert ix.versions_in_subtree("shot020") == []
assert ix.versions_in_subtree("project") == ["v001", "v002", "v003"]

# Mixed-entity type filter.
assert ix.entities_of_type("folder") == ["assets", "project", "shot010", "shot020", "shots"]
assert ix.entities_of_type("task") == ["t_comp", "t_layout", "t_model"]
assert ix.entities_of_type("product") == ["p_cache", "p_render"]
assert ix.entities_of_type("version") == ["v001", "v002", "v003"]

# Validation errors on bad links.
try:
    ix.add_folder("orphan_child", parent="ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    ix.attach_chain(product=("p_bad", "ghost_task"))
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Deep tree: path and inheritance reach level-3+ ancestors; cycles stop.
deep = EntityIndex()
for i, parent in [(0, None), (1, "d0"), (2, "d1"), (3, "d2")]:
    attrs = {"level": i} if i in (0, 2) else None
    deep.add_folder("d%d" % i, parent=parent, attrs=attrs)
assert deep.canonical_path("d3") == "d0/d1/d2/d3"
assert deep.inherited_attribute("d3", "level") == 2   # nearest wins over d0's 0
cyc = EntityIndex()
cyc.folder_parent["x"] = "y"
cyc.folder_parent["y"] = "x"
cyc.folder_children = {"x": [], "y": []}
cyc.attr_values = {}
assert cyc.canonical_path("x").count("/") <= 1        # stops, no hang
