"""Reference harness: exercises every public function of iss_VectifyAI__PageIndex__316."""
import importlib

mod = importlib.import_module("iss_VectifyAI__PageIndex__316")
diff_versions = mod.diff_versions
reindex = mod.reindex

doc = {
    "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
    "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
    "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
    "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
    "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
    "s2": {"parent": "root", "children": [], "hash": "h-s2"},
}

# diff_versions: content hash change, addition, removal, no-change
v2 = {k: dict(v) for k, v in doc.items()}
v2["s1b"]["hash"] = "h-s1b-v2"
v2["s3"] = {"parent": "root", "children": [], "hash": "h-s3"}
del v2["s2"]
assert diff_versions(doc, v2) == ["s1b", "s2", "s3"]
assert diff_versions(doc, doc) == []

# reindex a leaf: rebuild just the leaf, resummarize its ancestor chain
res = reindex(doc, ["s1a1"])
assert res == {"rebuilt": ["s1a1"], "resummarized": ["root", "s1", "s1a"]}

# reindex a mid-level section: rebuild the whole affected subtree
res = reindex(doc, ["s1"])
assert res == {"rebuilt": ["s1", "s1a", "s1a1", "s1b"], "resummarized": ["root"]}

# changed parent and child together: the parent is rebuilt, not resummarized
res = reindex(doc, ["s1", "s1a1"])
assert res == {"rebuilt": ["s1", "s1a", "s1a1", "s1b"], "resummarized": ["root"]}

# sibling changes under one parent: one resummarization of the shared chain
res = reindex(doc, ["s1a1", "s1b"])
assert res == {"rebuilt": ["s1a1", "s1b"], "resummarized": ["root", "s1", "s1a"]}

# shared subtree guard: overlapping changed sets dedup the rebuild sweep
res = reindex(doc, ["s1", "s1a1"])
assert res["rebuilt"].count("s1a1") == 1

# root change: everything rebuilds, nothing left to resummarize
res = reindex(doc, ["root"])
assert res == {"rebuilt": ["root", "s1", "s1a", "s1a1", "s1b", "s2"], "resummarized": []}

# changed sections across disjoint branches
res = reindex(doc, ["s1b", "s2"])
assert res == {"rebuilt": ["s1b", "s2"], "resummarized": ["root", "s1"]}

# unknown section ids are skipped; empty change set rebuilds nothing
assert reindex(doc, ["ghost"]) == {"rebuilt": [], "resummarized": []}
assert reindex(doc, ["ghost", "s2"]) == {"rebuilt": ["s2"], "resummarized": ["root"]}
assert reindex(doc, []) == {"rebuilt": [], "resummarized": []}

# forest of roots: ancestor chains stop at each tree's own root
forest = {
    "a": {"parent": None, "children": ["a1"], "hash": "h-a"},
    "a1": {"parent": "a", "children": [], "hash": "h-a1"},
    "b": {"parent": None, "children": ["b1"], "hash": "h-b"},
    "b1": {"parent": "b", "children": [], "hash": "h-b1"},
}
res = reindex(forest, ["b1"])
assert res == {"rebuilt": ["b1"], "resummarized": ["b"]}

print("iss_VectifyAI__PageIndex__316 ref OK")
