"""TechnicallyJoe/terraform-motf#54 — recursive module extraction closure."""

node Module {
    has mid: str;
    has name: str;
    has path: str;
    has is_remote: bool = False;
}

edge ModuleRef {}

node ModuleGraph {
    has modules_by_id: dict[str, Module] = {};
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Module entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        self.found.append(here.mid);
        print(f"closure visit {here.mid}");
        deps: list[Module] = [here ->:ModuleRef:->][?:Module];
        for dep in deps {
            visit :0: [dep];
        }
    }
}

def create_module_graph() -> ModuleGraph {
    g = ModuleGraph();
    root ++> g;
    return g;
}

def add_module(
    graph: ModuleGraph,
    mid: str,
    name: str,
    path: str,
    is_remote: bool = False,
) -> None {
    m = Module(mid=mid, name=name, path=path, is_remote=is_remote);
    root ++> m;
    graph.modules_by_id[mid] = m;
}

def add_module_reference(graph: ModuleGraph, from_mid: str, to_mid: str) -> None {
    src = graph.modules_by_id[from_mid] as Module;
    dst = graph.modules_by_id[to_mid] as Module;
    src +>:ModuleRef:+> dst;
}

def collect_dependency_closure(graph: ModuleGraph, root_mid: str) -> list[str] {
    if root_mid not in graph.modules_by_id {
        return [];
    }
    start = graph.modules_by_id[root_mid] as Module;
    w = start spawn ClosureWalker(claimed={});
    found: list[str] = w.found;
    found.sort();
    return found;
}

def extract_module_bundle(graph: ModuleGraph, root_mid: str) -> dict {
    empty_ids: list[str] = [];
    empty_pairs: list[list] = [];
    if root_mid not in graph.modules_by_id {
        out: dict = {};
        out["module_ids"] = empty_ids;
        out["reference_pairs"] = empty_pairs;
        return out;
    }
    ids = collect_dependency_closure(graph, root_mid);
    in_closure: dict[str, bool] = {};
    for mid in ids {
        in_closure[mid] = True;
    }
    pairs: list[list] = [];
    for mid in ids {
        m = graph.modules_by_id[mid] as Module;
        deps: list[Module] = [m ->:ModuleRef:->][?:Module];
        for dep in deps {
            if dep.mid in in_closure {
                pair: list = [];
                pair.append(mid);
                pair.append(dep.mid);
                pairs.append(pair);
            }
        }
    }
    pairs.sort();
    result: dict = {};
    result["module_ids"] = ids;
    result["reference_pairs"] = pairs;
    return result;
}
