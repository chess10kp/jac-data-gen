"""Incremental index updates for a document section tree, lifted to OSP.

Sections become Section nodes; the children lists and parent pointers
become typed Contains edges (parent -> child). The recursive descent over
children lists becomes a downward Rebuild walker cascading through
Contains edges -- its claim map IS the once-only guard for shared
subtrees; the link-by-link parent-pointer walk becomes an upward
Resummarize walker over reverse Contains edges that skips the changed
section it starts from. Hash-based change detection stays dict comparison:
it is domain logic, not traversal. A section that is itself rebuilt is
not resummarized; unknown section ids are skipped.
Ref: VectifyAI/PageIndex#316
"""
node Section {
    has sid: str;
}
edge Contains {}

"""Loader handle: section ids resolve through this lookup map."""
obj Doc {
    has sections: dict[str, Section];

    def resolve(sid: str) -> Section | None {
        return self.sections.get(sid);
    }
}

"""Deterministic fresh-graph builder from a {sid: {parent, children}} spec."""
def load_doc(tree: dict) -> Doc {
    d = Doc(sections={});
    for sid in tree.keys() {
        s = Section(sid=sid);
        root ++> s;
        d.sections[sid] = s;
    }
    for sid in tree.keys() {
        entry: dict = tree[sid];
        kids: list = entry.get("children", []);
        parent = d.resolve(sid);
        for kid in kids {
            k = d.resolve(kid);
            if k is not None and parent is not None {
                parent +>:Contains:+> k;
            }
        }
    }
    return d;
}

"""Downward cascade: everything beneath a changed section rebuilds."""
walker RebuildWalk {
    has claimed: dict[str, bool] = {};
    has rebuilt: list[str] = [];

    can step with Section entry {
        # Cycle policy / shared-subtree guard: rebuild each section once.
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.rebuilt.append(here.sid);
        visit [->:Contains:->];
    }
}

"""Upward chain: summaries recompute along impacted ancestor paths only."""
walker ResummarizeWalk {
    has claimed: dict[str, bool] = {};
    has anc: list[str] = [];
    has at_start: bool = True;

    can step with Section entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if self.at_start {
            # the changed section itself is rebuilt, not resummarized
            self.at_start = False;
        } else {
            if here.sid not in self.anc {
                self.anc.append(here.sid);
            }
        }
        visit [<-:Contains:<-];
    }
}

"""Rebuild only affected subtrees and impacted ancestor paths."""
def reindex(tree: dict, changed: list) -> dict {
    d = load_doc(tree);
    rebuilt: list[str] = [];
    resummarized: list[str] = [];
    for sid in changed {
        s = d.resolve(sid);
        if s is None {
            continue;  # unknown section: nothing to reindex
        }
        w = s spawn RebuildWalk(claimed={}, rebuilt=[]);
        for r in w.rebuilt {
            if r not in rebuilt {
                rebuilt.append(r);
            }
        }
        u = s spawn ResummarizeWalk(claimed={}, anc=[], at_start=True);
        for a in u.anc {
            if a not in resummarized {
                resummarized.append(a);
            }
        }
    }
    # a rebuilt section is not resummarized
    kept: list[str] = [];
    for a in resummarized {
        if a not in rebuilt {
            kept.append(a);
        }
    }
    return {"rebuilt": sorted(rebuilt), "resummarized": sorted(kept)};
}

"""Section ids whose content hash differs between two document versions."""
def diff_versions(old: dict, new: dict) -> list {
    out: list[str] = [];
    for sid in old.keys() {
        if sid not in new {
            out.append(sid);
        } else {
            if old[sid]["hash"] != new[sid]["hash"] {
                out.append(sid);
            }
        }
    }
    for sid in new.keys() {
        if sid not in old {
            out.append(sid);
        }
    }
    return sorted(out);
}


test "diff_versions detects hash change, addition, removal" {
    doc = {
        "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
        "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
        "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
        "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
        "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
        "s2": {"parent": "root", "children": [], "hash": "h-s2"},
    };
    v2 = {};
    for k in doc.keys() {
        e: dict = doc[k];
        v2[k] = {"parent": e["parent"], "children": list(e["children"]), "hash": e["hash"]};
    }
    v2["s1b"]["hash"] = "h-s1b-v2";
    v2["s3"] = {"parent": "root", "children": [], "hash": "h-s3"};
    del v2["s2"];
    assert diff_versions(doc, v2) == ["s1b", "s2", "s3"];
    assert diff_versions(doc, doc) == [];
}

test "leaf change rebuilds the leaf and resummarizes its ancestor chain" {
    doc = {
        "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
        "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
        "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
        "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
        "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
        "s2": {"parent": "root", "children": [], "hash": "h-s2"},
    };
    res = reindex(doc, ["s1a1"]);
    assert res == {"rebuilt": ["s1a1"], "resummarized": ["root", "s1", "s1a"]};
}

test "mid-level change rebuilds the whole affected subtree" {
    doc = {
        "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
        "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
        "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
        "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
        "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
        "s2": {"parent": "root", "children": [], "hash": "h-s2"},
    };
    res = reindex(doc, ["s1"]);
    assert res == {"rebuilt": ["s1", "s1a", "s1a1", "s1b"], "resummarized": ["root"]};
    # changed parent and child together: the parent is rebuilt, not resummarized
    res = reindex(doc, ["s1", "s1a1"]);
    assert res == {"rebuilt": ["s1", "s1a", "s1a1", "s1b"], "resummarized": ["root"]};
    # overlapping changed sets dedup the rebuild sweep
    res = reindex(doc, ["s1", "s1a1"]);
    assert res["rebuilt"].count("s1a1") == 1;
}

test "sibling changes share one ancestor resummarization" {
    doc = {
        "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
        "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
        "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
        "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
        "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
        "s2": {"parent": "root", "children": [], "hash": "h-s2"},
    };
    res = reindex(doc, ["s1a1", "s1b"]);
    assert res == {"rebuilt": ["s1a1", "s1b"], "resummarized": ["root", "s1", "s1a"]};
    res = reindex(doc, ["s1b", "s2"]);
    assert res == {"rebuilt": ["s1b", "s2"], "resummarized": ["root", "s1"]};
}

test "root change rebuilds everything and resummarizes nothing" {
    doc = {
        "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
        "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
        "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
        "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
        "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
        "s2": {"parent": "root", "children": [], "hash": "h-s2"},
    };
    res = reindex(doc, ["root"]);
    assert res == {"rebuilt": ["root", "s1", "s1a", "s1a1", "s1b", "s2"], "resummarized": []};
}

test "unknown section ids are skipped" {
    doc = {
        "root": {"parent": None, "children": ["s1", "s2"], "hash": "h-root"},
        "s1": {"parent": "root", "children": ["s1a", "s1b"], "hash": "h-s1"},
        "s1a": {"parent": "s1", "children": ["s1a1"], "hash": "h-s1a"},
        "s1a1": {"parent": "s1a", "children": [], "hash": "h-s1a1"},
        "s1b": {"parent": "s1", "children": [], "hash": "h-s1b"},
        "s2": {"parent": "root", "children": [], "hash": "h-s2"},
    };
    res = reindex(doc, ["ghost"]);
    assert res == {"rebuilt": [], "resummarized": []};
    res = reindex(doc, ["ghost", "s2"]);
    assert res == {"rebuilt": ["s2"], "resummarized": ["root"]};
    res = reindex(doc, []);
    assert res == {"rebuilt": [], "resummarized": []};
}

test "forest of roots: ancestor chains stop at each tree's own root" {
    forest = {
        "a": {"parent": None, "children": ["a1"], "hash": "h-a"},
        "a1": {"parent": "a", "children": [], "hash": "h-a1"},
        "b": {"parent": None, "children": ["b1"], "hash": "h-b"},
        "b1": {"parent": "b", "children": [], "hash": "h-b1"},
    };
    res = reindex(forest, ["b1"]);
    assert res == {"rebuilt": ["b1"], "resummarized": ["b"]};
}
