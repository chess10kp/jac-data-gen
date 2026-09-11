"""Guard: LordOfMyatar/Radoub#2638."""

obj AnimGraph { has clips: dict[str, AnimClip] = {}; }
node AnimClip { has cid: str; has key: str; has source: str; }
edge ChildOf {}
edge DependsOn {}

walker MergeWalk {
    has claimed: dict[str, bool] = {};
    has keys: list[str] = [];
    has sources: list[str] = [];
    has seen_keys: dict[str, bool] = {};
    has seen_sources: dict[str, bool] = {};

    can step with AnimClip entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.key != "" and here.key not in self.seen_keys {
            self.seen_keys[here.key] = True;
            self.keys.append(here.key);
        }
        if here.source != "" and here.source not in self.seen_sources {
            self.seen_sources[here.source] = True;
            self.sources.append(here.source);
        }
        visit [->:ChildOf:->];
        visit [->:DependsOn:->];
    }
}

def load_animations(
    clips: list[tuple[str, str, str]],
    child_edges: list[tuple[str, str]],
    dep_edges: list[tuple[str, str]],
) -> AnimGraph {
    mp: dict[str, AnimClip] = {};
    for (cid, key, source) in clips {
        clip = AnimClip(cid=cid, key=key, source=source);
        root ++> clip;
        mp[cid] = clip;
    }
    for (parent, child) in child_edges {
        a = mp.get(parent, None);
        b = mp.get(child, None);
        if a is not None and b is not None { a +>:ChildOf:+> b; }
    }
    for (src, dst) in dep_edges {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return AnimGraph(clips=mp);
}

def merge_sources(g: AnimGraph, target: str) -> list[str] {
    anchor = g.clips.get(target, None);
    if anchor is None { return []; }
    w = anchor spawn MergeWalk(
        claimed={},
        keys=[],
        sources=[],
        seen_keys={},
        seen_sources={},
    );
    return sorted(w.sources);
}

def merged_keys(g: AnimGraph, target: str) -> list[str] {
    anchor = g.clips.get(target, None);
    if anchor is None { return []; }
    w = anchor spawn MergeWalk(
        claimed={},
        keys=[],
        sources=[],
        seen_keys={},
        seen_sources={},
    );
    return sorted(w.keys);
}

test "linear qm and reliquary merge" {
    g = load_animations(
        [
            ("sm", "", ""),
            ("qm_idle", "idle", "qm"),
            ("rel_walk", "walk", "reliquary"),
        ],
        [("sm", "qm_idle"), ("qm_idle", "rel_walk")],
        [],
    );
    assert merge_sources(g, "sm") == ["qm", "reliquary"];
    assert merged_keys(g, "sm") == ["idle", "walk"];
}

test "diamond adversarial once per key and source" {
    g = load_animations(
        [
            ("sm", "", ""),
            ("left", "gate", "qm"),
            ("right", "gate", "reliquary"),
            ("shared", "shared", "qm"),
            ("deep", "deep", "reliquary"),
        ],
        [
            ("sm", "right"),
            ("sm", "left"),
            ("right", "shared"),
            ("left", "shared"),
            ("shared", "deep"),
        ],
        [],
    );
    assert merge_sources(g, "sm") == ["qm", "reliquary"];
    assert merged_keys(g, "sm") == ["deep", "gate", "shared"];
}

test "depends cycle terminates once per node" {
    g = load_animations(
        [("a", "ka", "qm"), ("b", "kb", "reliquary"), ("c", "kc", "qm")],
        [],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert merge_sources(g, "a") == ["qm", "reliquary"];
    assert merged_keys(g, "a") == ["ka", "kb", "kc"];
}

test "unknown target tolerant" {
    g = load_animations([("only", "k", "qm")], [], []);
    assert merge_sources(g, "missing") == [];
    assert merged_keys(g, "missing") == [];
}
