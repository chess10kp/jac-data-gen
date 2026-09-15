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

test "linear_nested_closure" {
    g = create_module_graph();
    add_module(g, "root_mod", "root", "./modules/root", False);
    add_module(g, "child", "child", "./modules/child", False);
    add_module(g, "grand", "grand", "./modules/grand", False);
    add_module_reference(g, "root_mod", "child");
    add_module_reference(g, "child", "grand");
    got = collect_dependency_closure(g, "root_mod");
    assert got == ["child", "grand", "root_mod"];
}

test "diamond_adversarial_revisit" {
    g = create_module_graph();
    add_module(g, "a", "a", "./a", False);
    add_module(g, "b", "b", "./b", False);
    add_module(g, "c", "c", "./c", False);
    add_module(g, "d", "d", "./d", False);
    add_module_reference(g, "a", "b");
    add_module_reference(g, "a", "c");
    add_module_reference(g, "b", "d");
    add_module_reference(g, "c", "d");
    got = collect_dependency_closure(g, "a");
    assert got == ["a", "b", "c", "d"];
    bundle = extract_module_bundle(g, "a");
    assert bundle["module_ids"] == ["a", "b", "c", "d"];
    assert bundle["reference_pairs"] == [["a", "b"], ["a", "c"], ["b", "d"], ["c", "d"]];
}

test "cycle_policy_once_only" {
    g = create_module_graph();
    add_module(g, "x", "x", "./x", False);
    add_module(g, "y", "y", "./y", False);
    add_module_reference(g, "x", "y");
    add_module_reference(g, "y", "x");
    got = collect_dependency_closure(g, "x");
    assert got == ["x", "y"];
}

test "unknown_root_empty" {
    g = create_module_graph();
    add_module(g, "only", "only", "./only", False);
    assert collect_dependency_closure(g, "missing") == [];
    bundle = extract_module_bundle(g, "missing");
    assert bundle["module_ids"] == [];
    assert bundle["reference_pairs"] == [];
}

test "remote_nested_included" {
    g = create_module_graph();
    add_module(g, "app", "app", "./app", False);
    add_module(g, "vpc", "vpc", "git::ssh://example/vpc", True);
    add_module_reference(g, "app", "vpc");
    got = collect_dependency_closure(g, "app");
    assert got == ["app", "vpc"];
}
