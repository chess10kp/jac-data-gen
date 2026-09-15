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
