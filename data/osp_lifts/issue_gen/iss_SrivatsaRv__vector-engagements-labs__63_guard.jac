"""SrivatsaRv/vector-engagements-labs#63 — Change-aware test layer dependency reachability."""

node Layer {
    has name: str;
}

edge LayerDepends {}

obj LayerStore {
    has layers: dict[str, Layer] = {};
}

walker DepWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Layer entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor {
            self.found.append(here.name);
        }
        visit [->:LayerDepends:->][?:Layer];
    }
}

walker CycleWalk {
    has stack: dict[str, bool] = {};
    has cyclic: bool = False;

    can step with Layer entry {
        if here.name in self.stack {
            self.cyclic = True;
            disengage;
        }
        self.stack[here.name] = True;
        visit [->:LayerDepends:->][?:Layer];
        del self.stack[here.name];
    }
}

def load_layers(
    layer_names: list[str],
    depends_edges: list[tuple[str, str]],
) -> LayerStore {
    store = LayerStore();
    for name in layer_names {
        nd = Layer(name=name);
        root ++> nd;
        store.layers[name] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = store.layers.get(upstream, None);
        d = store.layers.get(downstream, None);
        if u is not None and d is not None { d +>:LayerDepends:+> u; }
    }
    return store;
}

def required_layers(store: LayerStore, changed: list[str]) -> list[str] {
    result: dict[str, bool] = {};
    for layer in changed {
        nd = store.layers.get(layer, None);
        if nd is None { continue; }
        w = nd spawn DepWalk(claimed={}, anchor=layer);
        for name in w.found { result[name] = True; }
        result[layer] = True;
    }
    out: list[str] = [];
    for k in result { out.append(k); }
    return sorted(out);
}

def has_cycle(store: LayerStore) -> bool {
    for name in store.layers {
        nd = store.layers[name];
        w = nd spawn CycleWalk(stack={});
        if w.cyclic { return True; }
    }
    return False;
}

def transitive_deps(store: LayerStore, layer: str) -> list[str] {
    nd = store.layers.get(layer, None);
    if nd is None { return []; }
    w = nd spawn DepWalk(claimed={}, anchor=layer);
    return sorted(w.found);
}

test "layer dependency reachability" {
    store = load_layers(
        ["ci-local", "worker", "frontend", "integration", "browser"],
        [
            ("ci-local", "worker"),
            ("ci-local", "frontend"),
            ("frontend", "browser"),
            ("integration", "browser"),
        ],
    );
    assert required_layers(store, ["browser"]) == ["browser", "ci-local", "frontend", "integration"];
    assert required_layers(store, ["integration", "worker"]) == [
        "ci-local",
        "integration",
        "worker",
    ];
    assert has_cycle(store) is False;
    assert transitive_deps(store, "browser") == ["ci-local", "frontend", "integration"];
}
