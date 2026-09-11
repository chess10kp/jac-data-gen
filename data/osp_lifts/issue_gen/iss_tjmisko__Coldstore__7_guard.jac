"""tjmisko/Coldstore#7 — candidate + hidden guards."""

obj TagCatalog { has stamp: int = 0; }
node Tag { has path: str; }
edge SubtagOf {}

walker Descendants {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start: str = "";
    can begin with Root entry {
        for t in [-->][?:Tag] { if t.path == self.start { visit [t]; } }
    }
    can step with Tag entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.path != self.start { self.found.append(here.path); }
        visit [->:SubtagOf:->][?:Tag];
    }
    can finish with Root exit { report self.found; }
}

walker CollectDelete {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has start: str = "";
    can begin with Root entry {
        for t in [-->][?:Tag] { if t.path == self.start { visit [t]; } }
    }
    can step with Tag entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.found.append(here.path);
        visit [->:SubtagOf:->][?:Tag];
    }
    can finish with Root exit { report self.found; }
}

def _tag(path: str) -> Tag | None {
    for t in [-->][?:Tag] { if t.path == path { return t; } }
    return None;
}

def _path_depth(p: str) -> int { return p.count("/"); }

def _wire(paths: list[str]) {
    mp: dict[str, Tag] = {};
    for raw in paths {
        parts = [p for p in raw.split("/") if p];
        for i in range(len(parts)) {
            name = "/".join(parts[: i + 1]);
            if name in mp { continue; }
            n = Tag(path=name);
            root ++> n;
            mp[name] = n;
            if i > 0 {
                par_name = "/".join(parts[:i]);
                if par_name in mp {
                    parent = mp[par_name];
                    parent +>:SubtagOf:+> n;
                }
            }
        }
    }
}

def _remove_tag_node(t: Tag) {
    for ch in [t ->:SubtagOf:->][?:Tag] { t del ->:SubtagOf:-> ch; }
    for par in [t <-:SubtagOf:<-][?:Tag] { par del ->:SubtagOf:-> t; }
    del t;
}

def load_tags(paths: list[str]) -> TagCatalog {
    _wire(paths);
    return TagCatalog(stamp=1);
}

def descendant_tags(c: TagCatalog, name: str) -> list[str] {
    _ = c;
    if _tag(name) is None { return []; }
    w = root spawn Descendants(start=name, claimed={}, found=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def delete_tag(c: TagCatalog, name: str, cascade: bool = False) -> list[str] {
    _ = c;
    if _tag(name) is None { return []; }
    kids = descendant_tags(c, name);
    if kids and not cascade { raise ValueError("has_descendants"); }
    w = root spawn CollectDelete(start=name, claimed={}, found=[]);
    doomed = sorted(w.reports[0] if w.reports else []);
    by_depth = sorted(doomed, key=_path_depth, reverse=True);
    for p in by_depth {
        t = _tag(p);
        if t is not None { _remove_tag_node(t); }
    }
    return doomed;
}

def merge_tags(c: TagCatalog, src: str, dst: str) -> bool {
    _ = c;
    s = _tag(src);
    d = _tag(dst);
    if s is None or d is None { return False; }
    kids: list[Tag] = [];
    for ch in [s ->:SubtagOf:->][?:Tag] { kids.append(ch); }
    for ch in kids {
        s del ->:SubtagOf:-> ch;
        d +>:SubtagOf:+> ch;
    }
    _remove_tag_node(s);
    return True;
}

test "materialized ancestors and subtree multiset" {
    c = load_tags(["Trips/Iceland/Reykjavik", "Trips/Norway/Oslo", "Books/Fiction"]);
    assert descendant_tags(c, "Trips") == [
        "Trips/Iceland", "Trips/Iceland/Reykjavik", "Trips/Norway", "Trips/Norway/Oslo",
    ];
    assert descendant_tags(c, "Books") == ["Books/Fiction"];
}

test "delete leaf removes one tag" {
    c = load_tags(["A/B", "A/C"]);
    assert delete_tag(c, "A/B") == ["A/B"];
    assert descendant_tags(c, "A") == ["A/C"];
}

test "delete parent without cascade raises" {
    c = load_tags(["A/B/C"]);
    raised = False;
    try {
        delete_tag(c, "A");
    } except ValueError as e {
        raised = True;
        assert str(e) == "has_descendants";
    }
    assert raised;
}

test "cascade delete removes full subtree once" {
    c = load_tags(["A/B/C", "A/D"]);
    assert delete_tag(c, "A", cascade=True) == ["A", "A/B", "A/B/C", "A/D"];
    assert descendant_tags(c, "A") == [];
}

test "merge reparents children and drops src" {
    c = load_tags(["A/B", "C/D"]);
    assert merge_tags(c, "A", "C") is True;
    assert descendant_tags(c, "C") == ["A/B", "C/D"];
    assert merge_tags(c, "A", "C") is False;
}

test "unknown tag tolerant" {
    c = load_tags(["X"]);
    assert descendant_tags(c, "missing") == [];
    assert delete_tag(c, "missing") == [];
    assert merge_tags(c, "X", "missing") is False;
}

test "branched subtree after merge still acyclic" {
    # Path materialization is tree-shaped; merge preserves acyclicity.
    # Adversarial edge order: load deep branch before sibling branch.
    c = load_tags(["hub/left/leaf", "hub/right/mid/leaf2", "hub/right"]);
    assert descendant_tags(c, "hub") == [
        "hub/left", "hub/left/leaf", "hub/right", "hub/right/mid", "hub/right/mid/leaf2",
    ];
    assert merge_tags(c, "hub/left", "hub/right") is True;
    assert descendant_tags(c, "hub") == [
        "hub/left/leaf", "hub/right", "hub/right/mid", "hub/right/mid/leaf2",
    ];
}
