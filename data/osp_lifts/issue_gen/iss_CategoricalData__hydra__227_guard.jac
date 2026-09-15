"""Polymorphic recursion via annotated let bindings — CategoricalData/hydra#227."""

node Binding {
    has name: str;
    has scheme: str = "";
    has inferred: str = "";
}

edge Depends {}

walker IndexWalker {
    has by_name: dict[str, Binding] = {};
    has claimed: dict[str, bool] = {};

    can index with Binding entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.by_name[here.name] = here;
        outs: list[Binding] = [here ->:Depends:->][?:Binding];
        for nxt in outs {
            visit :0: [nxt];
        }
        ins: list[Binding] = [->:Depends:-> here][?:Binding];
        for prv in ins {
            visit :0: [prv];
        }
        print("index", here.name);
    }
}

walker TopoWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has ctx: dict[str, Binding] = {};

    can topo with Binding entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        deps: list[Binding] = [here ->:Depends:->][?:Binding];
        dep_names: list[str] = [];
        for dep in deps {
            dep_names.append(dep.name);
        }
        for nm in sorted(dep_names) {
            if nm in self.ctx {
                visit :0: [self.ctx[nm]];
            }
        }
        self.order.append(here.name);
        print("topo", self.order);
    }
}

def unify_mono(left: str, right: str) -> str {
    if left == "" {
        return right;
    }
    if right == "" {
        return left;
    }
    if left == right {
        return left;
    }
    return left + "&" + right;
}

def index_bindings(graph_root: Binding) -> dict[str, Binding] {
    iw = graph_root spawn IndexWalker(claimed={});
    return iw.by_name;
}

def topo_sort_bindings(graph_root: Binding) -> list[str] {
    by_name: dict[str, Binding] = index_bindings(graph_root);
    tw = graph_root spawn TopoWalker(claimed={}, ctx=by_name);
    return tw.order;
}

def infer_binding_type(node: Binding, memo: dict[str, str]) -> str {
    if node.scheme != "" {
        return node.scheme;
    }
    deps: list[Binding] = [node ->:Depends:->][?:Binding];
    dep_names: list[str] = [];
    for dep in deps {
        dep_names.append(dep.name);
    }
    acc: str = "";
    for nm in sorted(dep_names) {
        dt: str = "mono";
        if nm in memo {
            dt = memo[nm];
        }
        acc = unify_mono(acc, dt);
    }
    if acc == "" {
        return "mono";
    }
    return acc;
}

def infer_polymorphic_lets(graph_root: Binding) -> dict[str, str] {
    by_name: dict[str, Binding] = index_bindings(graph_root);
    order: list[str] = topo_sort_bindings(graph_root);
    out: dict[str, str] = {};
    for nm in order {
        if nm in by_name {
            node = by_name[nm];
            ty = infer_binding_type(node, out);
            out[nm] = ty;
        }
    }
    return out;
}

def binding_by_name(graph_root: Binding, name: str) -> Binding | None {
    by_name: dict[str, Binding] = index_bindings(graph_root);
    if name in by_name {
        return by_name[name];
    }
    return None;
}

test "index_bindings_covers_component" {
    leaf1 = Binding(name="leaf1", scheme="int");
    leaf2 = Binding(name="leaf2", scheme="float");
    hub = Binding(name="hub", scheme="");
    root ++> leaf1;
    root ++> leaf2;
    root ++> hub;
    hub +>:Depends:+> leaf1;
    hub +>:Depends:+> leaf2;
    idx = index_bindings(hub);
    assert ("leaf1" in idx);
    assert ("leaf2" in idx);
    assert ("hub" in idx);
    assert (len(idx) == 3);
}

test "topo_sort_dependencies_first" {
    leaf1 = Binding(name="leaf1", scheme="int");
    leaf2 = Binding(name="leaf2", scheme="float");
    hub = Binding(name="hub", scheme="");
    root ++> leaf1;
    root ++> leaf2;
    root ++> hub;
    hub +>:Depends:+> leaf1;
    hub +>:Depends:+> leaf2;
    order = topo_sort_bindings(hub);
    assert (order.index("leaf1") < order.index("hub"));
    assert (order.index("leaf2") < order.index("hub"));
    assert (order[-1] == "hub");
}

test "infer_polymorphic_lets_unifies_deps" {
    leaf1 = Binding(name="leaf1", scheme="int");
    leaf2 = Binding(name="leaf2", scheme="float");
    hub = Binding(name="hub", scheme="");
    root ++> leaf1;
    root ++> leaf2;
    root ++> hub;
    hub +>:Depends:+> leaf1;
    hub +>:Depends:+> leaf2;
    types = infer_polymorphic_lets(hub);
    assert (types["leaf1"] == "int");
    assert (types["leaf2"] == "float");
    assert (types["hub"] == "int&float");
}

test "infer_mono_default_no_deps" {
    solo = Binding(name="solo", scheme="");
    root ++> solo;
    types = infer_polymorphic_lets(solo);
    assert (types["solo"] == "mono");
}

test "binding_by_name_found_and_missing" {
    leaf1 = Binding(name="leaf1", scheme="int");
    hub = Binding(name="hub", scheme="");
    root ++> leaf1;
    root ++> hub;
    hub +>:Depends:+> leaf1;
    found = binding_by_name(hub, "leaf1");
    assert (found is not None);
    assert (found.name == "leaf1");
    missing = binding_by_name(hub, "nope");
    assert (missing is None);
}
