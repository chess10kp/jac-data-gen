"""Synthetic inference graph for astral-sh/ty#4443 recursive union cycle limits."""

node TypeDef {
    has name: str;
    has kind: str;
    has deps: list[str] = [];
}

edge Refers {}

obj TypeGraph {
    has by_name: dict[str, TypeDef] = {};
}

def _kind_for(name: str, deps: list[str]) -> str {
    if name in deps {
        return "union";
    }
    if len(deps) == 1 {
        return "tuple";
    }
    if len(deps) > 1 {
        return "union";
    }
    return "atom";
}

def _join_parts(parts: list[str]) -> str {
    out: str = "";
    i: int = 0;
    for p in parts {
        if i > 0 {
            out = out + ",";
        }
        out = out + p;
        i = i + 1;
    }
    return out;
}

def _render_def(here: TypeDef, inferred: dict[str, str]) -> str {
    if here.kind == "tuple" {
        inner: str = here.name;
        if len(here.deps) > 0 {
            d0: str = here.deps[0];
            if d0 in inferred {
                inner = inferred[d0];
            } else {
                inner = d0;
            }
        }
        return "tuple(" + inner + ")";
    }
    if here.kind == "union" {
        parts: list[str] = [];
        for d in sorted(here.deps) {
            if d in inferred {
                parts.append(inferred[d]);
            } else {
                parts.append(d);
            }
        }
        return "union(" + _join_parts(parts) + ")";
    }
    return here.name;
}

def build_type_graph(spec: dict[str, list[str]]) -> TypeGraph {
    g = TypeGraph(by_name={});
    keys: list[str] = sorted(spec.keys());
    for nm in keys {
        dep_list: list[str] = spec[nm];
        kd: str = _kind_for(nm, dep_list);
        nd = TypeDef(name=nm, kind=kd, deps=dep_list);
        g.by_name[nm] = nd;
        root ++> nd;
    }
    for nm in keys {
        src = g.by_name[nm];
        dep_list2: list[str] = spec[nm];
        for dep_nm in dep_list2 {
            if dep_nm in g.by_name {
                tgt = g.by_name[dep_nm];
                src +>:Refers:+> tgt;
            }
        }
    }
    return g;
}

def _find_node(g: TypeGraph, name: str) -> TypeDef | None {
    if name in g.by_name {
        return g.by_name[name];
    }
    return None;
}

walker InferWalker {
    has claimed: dict[str, bool] = {};
    has inferred: dict[str, str] = {};

    can step with TypeDef entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        kids: list[TypeDef] = [];
        for ch in [here ->:Refers:->][?:TypeDef] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        }
        rep: str = _render_def(here, self.inferred);
        self.inferred[here.name] = rep;
        print("infer ", here.name, " -> ", rep);
        disengage;
    }
}

def infer_definition_types(g: TypeGraph, start: str) -> dict[str, str] {
    nd = _find_node(g, start);
    if nd is None {
        empty: dict[str, str] = {};
        return empty;
    }
    w = nd spawn InferWalker(claimed={}, inferred={});
    return w.inferred;
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can step with TypeDef entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        print("dep ", here.name);
        kids: list[TypeDef] = [];
        for ch in [here ->:Refers:->][?:TypeDef] {
            kids.append(ch);
        }
        visit :0: kids else { disengage; }
    }
}

def collect_dependencies(g: TypeGraph, start: str) -> list[str] {
    nd = _find_node(g, start);
    if nd is None {
        empty: list[str] = [];
        return empty;
    }
    w = nd spawn CollectWalker(claimed={}, names=[]);
    out: list[str] = w.names;
    out = sorted(out);
    return out;
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has saw_cycle: bool = False;

    can probe with TypeDef entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        kids: list[TypeDef] = [];
        for ch in [here ->:Refers:->][?:TypeDef] {
            if ch.name in self.claimed {
                self.saw_cycle = True;
            }
            kids.append(ch);
        }
        print("cycle ", here.name);
        visit :0: kids else { disengage; }
    }
}

def has_inference_cycle(g: TypeGraph, start: str) -> bool {
    nd = _find_node(g, start);
    if nd is None {
        return False;
    }
    w = nd spawn CycleWalker(claimed={}, saw_cycle=False);
    return w.saw_cycle;
}
