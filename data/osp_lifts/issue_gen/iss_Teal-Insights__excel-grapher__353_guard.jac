"""Guard: Teal-Insights/excel-grapher#353."""

obj WorkbookStore {
    has specs: dict[str, dict] = {};
    has cache: dict[str, str] = {};
}

node SheetNode {
    has nid: str;
    has kind: str;
}

edge Depends {}

walker InvalidateReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with SheetNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [<-:Depends:<-] else { disengage; };
    }
}

walker SerializeWalk {
    has parts: dict[str, str] = {};
    has claimed: dict[str, bool] = {};

    can step with SheetNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        visit [->:Depends:->] else { disengage; };
    }

    can finish with SheetNode exit {
        dep_parts: list[str] = [];
        for ch in [here ->:Depends:->][?:SheetNode] {
            piece = self.parts.get(ch.nid, "");
            if piece { dep_parts.append(piece); }
        }
        dep_parts = sorted(dep_parts);
        self.parts[here.nid] = (
            "node:" + here.nid + "|kind:" + here.kind
            + "|deps:[" + ",".join(dep_parts) + "]"
        );
    }
}

def _find(nid: str) -> SheetNode | None {
    for n in [-->][?:SheetNode] {
        if n.nid == nid { return n; }
    }
    return None;
}

def load_workbook(
    specs: dict[str, dict],
    edges: list[tuple[str, str]],
) -> WorkbookStore {
    mp: dict[str, SheetNode] = {};
    for nid in specs {
        fresh = SheetNode(nid=nid, kind=specs[nid].get("kind", "sheet"));
        root ++> fresh;
        mp[nid] = fresh;
    }
    for (src, dst) in edges {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None { a +>:Depends():+> b; }
    }
    return WorkbookStore(specs=specs, cache={});
}

def serialize_node(g: WorkbookStore, node_id: str) -> str {
    if node_id not in g.specs { return ""; }
    anchor = _find(node_id);
    if anchor is None { return ""; }
    w = anchor spawn SerializeWalk(parts={}, claimed={});
    return w.parts.get(node_id, "");
}

def cached_serialize(g: WorkbookStore, node_id: str) -> str {
    if node_id not in g.specs { return ""; }
    hit = g.cache.get(node_id, None);
    if hit is not None { return hit; }
    val = serialize_node(g, node_id);
    g.cache[node_id] = val;
    return val;
}

def dependency_reach(g: WorkbookStore, node_id: str) -> list[str] {
    if node_id not in g.specs { return []; }
    anchor = _find(node_id);
    if anchor is None { return []; }
    w = anchor spawn InvalidateReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def invalidate_node(g: WorkbookStore, node_id: str) -> list[str] {
    victims = dependency_reach(g, node_id);
    for vid in victims { g.cache.pop(vid, None); }
    return victims;
}

test "pure serialize chains deps" {
    g = load_workbook(
        {"data": {"kind": "sheet"}, "chart": {"kind": "chart"}, "export": {"kind": "export"}},
        [("chart", "data"), ("export", "chart")],
    );
    got = serialize_node(g, "export");
    assert got == "node:export|kind:export|deps:[node:chart|kind:chart|deps:[node:data|kind:sheet|deps:[]]]";
}

test "cache split from serialize" {
    g = load_workbook(
        {"data": {"kind": "sheet"}, "chart": {"kind": "chart"}},
        [("chart", "data")],
    );
    first = cached_serialize(g, "chart");
    second = cached_serialize(g, "chart");
    assert first == second;
    assert g.cache.get("chart", None) is not None;
}

test "invalidate clears downstream cache" {
    g = load_workbook(
        {"data": {"kind": "sheet"}, "chart": {"kind": "chart"}, "export": {"kind": "export"}},
        [("chart", "data"), ("export", "chart")],
    );
    cached_serialize(g, "export");
    victims = invalidate_node(g, "data");
    assert victims == ["chart", "data", "export"];
    assert len(g.cache) == 0;
}

test "diamond adversarial serialize once" {
    # hub->left/right wired before left/right->shared so revisit fires early
    g = load_workbook(
        {
            "hub": {"kind": "export"},
            "left": {"kind": "chart"},
            "right": {"kind": "chart"},
            "shared": {"kind": "sheet"},
        },
        [("hub", "left"), ("hub", "right"), ("left", "shared"), ("right", "shared")],
    );
    assert dependency_reach(g, "shared") == ["hub", "left", "right", "shared"];
    blob = serialize_node(g, "hub");
    assert blob.count("node:shared|kind:sheet|deps:[]") == 1;
}

test "unknown id tolerant" {
    g = load_workbook({"data": {"kind": "sheet"}}, []);
    assert serialize_node(g, "missing") == "";
    assert cached_serialize(g, "missing") == "";
    assert dependency_reach(g, "missing") == [];
    assert invalidate_node(g, "missing") == [];
}
