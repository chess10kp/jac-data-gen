"""sicara/tf-explain#63 — recursive model layer resolution for activation callbacks."""

node Layer {
    has name: str;
    has lid: str;
    has kind: str = "dense";
}

edge contains {}

walker ResolveNames {
    has claimed: dict[str, bool] = {};
    has targets: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Layer entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        print("resolve_visit", here.name);
        if here.name in self.targets {
            self.found.append(here.name);
        }
        kids: list[Layer] = [here ->:contains:->][?:Layer];
        for ch in kids {
            visit [ch];
        }
    }
}

walker LayerOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Layer entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        print("order_visit", here.name);
        self.order.append(here.name);
        kids: list[Layer] = [here ->:contains:->][?:Layer];
        for ch in kids {
            visit [ch];
        }
    }
}

def layer(name: str, lid: str, kind: str = "dense") -> Layer {
    nd = Layer(name=name, lid=lid, kind=kind);
    return nd;
}

def attach(parent: Layer, child: Layer) -> None {
    parent +>:contains:+> child;
}

def resolve_layer_names(root_node: Layer, names: list[str]) -> list[str] {
    targets: dict[str, bool] = {};
    for nm in names {
        targets[nm] = True;
    }
    w = root_node spawn ResolveNames(claimed={}, targets=targets, found=[]);
    out: list[str] = w.found;
    out = sorted(out);
    return out;
}

def recursive_layer_order(root_node: Layer) -> list[str] {
    w = root_node spawn LayerOrder(claimed={}, order=[]);
    return w.order;
}

def validate_callback_layers(root_node: Layer, names: list[str]) -> dict {
    resolved = resolve_layer_names(root_node, names);
    resolved_set: dict[str, bool] = {};
    for r in resolved {
        resolved_set[r] = True;
    }
    missing: list[str] = [];
    for nm in names {
        if nm not in resolved_set {
            missing.append(nm);
        }
    }
    missing = sorted(missing);
    ok = len(missing) == 0;
    result: dict = {};
    result["resolved"] = resolved;
    result["missing"] = missing;
    result["ok"] = ok;
    return result;
}
