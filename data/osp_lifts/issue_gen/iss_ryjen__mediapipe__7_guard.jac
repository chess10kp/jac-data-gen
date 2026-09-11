"""Guard: ryjen/mediapipe#7."""

node FeatureNode {
    has name: str;
    has supported: bool = False;
}

edge Requires {}

obj CapabilityGraph {
    has features: dict[str, FeatureNode] = {};
}

walker ReqClosure {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with FeatureNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<-:Requires:<-][?:FeatureNode];
    }
}

def load_capability_graph(
    features: list[str],
    requires: list[tuple[str, str]],
    supported: list[str],
) -> CapabilityGraph {
    g = CapabilityGraph();
    sup = {};
    for s in supported { sup[s] = True; }
    for f in features {
        nd = FeatureNode(name=f, supported=(f in sup));
        root ++> nd;
        g.features[f] = nd;
    }
    for (feat, req) in requires {
        fnd = g.features.get(feat, None);
        rnd = g.features.get(req, None);
        if fnd is not None and rnd is not None { rnd +>:Requires:+> fnd; }
    }
    return g;
}

def available_features(graph: CapabilityGraph) -> list[str] {
    ok: list[str] = [];
    for (name, nd) in graph.features.items() {
        if not nd.supported { continue; }
        blocked = False;
        for req in [nd <-:Requires:<-][?:FeatureNode] {
            if not req.supported { blocked = True; }
        }
        if not blocked { ok.append(name); }
    }
    return sorted(ok);
}

def dependency_closure(graph: CapabilityGraph, feature: str) -> list[str] {
    nd = graph.features.get(feature, None);
    if nd is None { return []; }
    w = nd spawn ReqClosure(claimed={}, reached=[]);
    return sorted(w.reached);
}

def blocked_by_missing(graph: CapabilityGraph, feature: str) -> list[str] {
    missing: list[str] = [];
    for req_name in dependency_closure(graph, feature) {
        req = graph.features.get(req_name, None);
        if req is not None and not req.supported { missing.append(req_name); }
    }
    return sorted(missing);
}

test "cpu-only capabilities" {
    g = load_capability_graph(
        ["text_gen", "cpu_backend", "cgimage_input", "gpu_accel"],
        [
            ("text_gen", "cpu_backend"),
            ("cgimage_input", "gpu_accel"),
            ("gpu_accel", "cpu_backend"),
        ],
        ["cpu_backend", "text_gen"],
    );
    assert available_features(g) == ["cpu_backend", "text_gen"];
    assert blocked_by_missing(g, "cgimage_input") == ["cgimage_input", "gpu_accel"];
}

test "diamond dependency closure" {
    g = load_capability_graph(
        ["hub", "left", "right", "leaf"],
        [
            ("left", "hub"),
            ("right", "hub"),
            ("leaf", "left"),
            ("leaf", "right"),
        ],
        ["hub", "left", "right", "leaf"],
    );
    assert dependency_closure(g, "leaf") == ["hub", "leaf", "left", "right"];
}
