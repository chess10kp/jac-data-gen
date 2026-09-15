"""diprism/perpl#123 — extern with recursive type."""

node ExternDecl {
    has name: str;
    has bound: str = "";
    has recursive: bool = False;
}

edge DependsOn {}

node ExternGraph {
    has by_name: dict[str, ExternDecl] = {};
}

def make_graph() -> ExternGraph {
    g = ExternGraph(by_name={});
    root ++> g;
    return g;
}

def _ensure_decl(g: ExternGraph, name: str) -> ExternDecl {
    nd: ExternDecl | None = None;
    if name in g.by_name {
        nd = g.by_name[name];
    } else {
        nd = ExternDecl(name=name);
        g.by_name[name] = nd;
    }
    return nd;
}

def register_extern(
    g: ExternGraph, name: str, deps: list[str], recursive: bool = False
) -> None {
    nd = _ensure_decl(g, name);
    nd.recursive = recursive;
    for dep_name in deps {
        dep_nd = _ensure_decl(g, dep_name);
        nd +>:DependsOn:+> dep_nd;
    }
}

walker RecursiveExternWalker {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can step with ExternDecl entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        kids: list[ExternDecl] = [here ->:DependsOn:->][?:ExternDecl];
        for kid in kids {
            visit :0: [kid];
        }
        print(here.name);
        root spawn RecursiveExternWalker(claimed={}, names=[]);
    }
}

def extern_closure(g: ExternGraph, root_name: str) -> list[str] {
    if root_name not in g.by_name {
        return [];
    }
    start = g.by_name[root_name];
    w = start spawn RecursiveExternWalker(claimed={}, names=[]);
    out: list[str] = [];
    for n in w.names {
        out.append(n);
    }
    return sorted(out);
}

def resolve_extern(g: ExternGraph, name: str) -> dict[str, object] | None {
    if name not in g.by_name {
        return None;
    }
    nd = g.by_name[name];
    deps: list[str] = [];
    kids: list[ExternDecl] = [nd ->:DependsOn:->][?:ExternDecl];
    for kid in kids {
        deps.append(kid.name);
    }
    out: dict[str, object] = {};
    out["name"] = nd.name;
    out["recursive"] = nd.recursive;
    out["bound"] = nd.bound;
    out["deps"] = sorted(deps);
    return out;
}

def bind_extern_string(g: ExternGraph, name: str, value: str) -> bool {
    if name not in g.by_name {
        return False;
    }
    g.by_name[name].bound = value;
    return True;
}

def is_recursive_wellformed(g: ExternGraph, name: str) -> bool {
    if name not in g.by_name {
        return False;
    }
    clos = extern_closure(g, name);
    return len(clos) > 0;
}

test "diamond_revisit_once" {
    g = make_graph();
    register_extern(g, "hub", ["left", "right"], False);
    register_extern(g, "left", ["sink"], False);
    register_extern(g, "right", ["sink"], False);
    clos = extern_closure(g, "hub");
    assert clos == ["hub", "left", "right", "sink"];;
}

test "unknown_ids_tolerant" {
    g = make_graph();
    assert resolve_extern(g, "ghost") is None;
    assert extern_closure(g, "ghost") == [];
    assert bind_extern_string(g, "ghost", "v") is False;
    assert is_recursive_wellformed(g, "ghost") is False;;
}

test "recursive_parser_grammar_cycle" {
    g = make_graph();
    register_extern(g, "Parser", ["Grammar"], True);
    register_extern(g, "Grammar", ["Parser"], False);
    info = resolve_extern(g, "Parser");
    assert info is not None;
    assert info["recursive"] is True;
    clos = extern_closure(g, "Parser");
    assert clos == ["Grammar", "Parser"];;
}

test "deps_sorted_adversarial_order" {
    g = make_graph();
    register_extern(g, "T", ["zeta", "alpha", "mu"], False);
    info = resolve_extern(g, "T");
    assert info is not None;
    assert info["deps"] == ["alpha", "mu", "zeta"];;
}

test "bind_and_resolve_roundtrip" {
    g = make_graph();
    register_extern(g, "Plug", [], True);
    ok = bind_extern_string(g, "Plug", "grammar.dll");
    assert ok is True;
    info = resolve_extern(g, "Plug");
    assert info is not None;
    assert info["bound"] == "grammar.dll";;
}
