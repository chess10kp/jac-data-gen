node Target { has tid: str; }
edge ImmediateDep {}
edge ProductDep {}

walker Discover {
    has visited: dict[str, bool] = {};
    has result: list[str] = [];
    can discover with Target entry {
        if here.tid in self.visited { skip; }
        self.visited[here.tid] = True;
        self.result.append(here.tid);
        print(here.tid);
        kids: list[Target] = [];
        for nxt in [here ->:ImmediateDep:->][?:Target] {
            kids.append(nxt);
        }
        for nxt in [here ->:ProductDep:->][?:Target] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def create_target(tid: str) -> Target {
    nd = Target(tid=tid);
    root ++> nd;
    return nd;
}

def add_immediate_dependency(src: Target, dst: Target) {
    src +>:ImmediateDep:+> dst;
}

def add_package_product_dependency(src: Target, dst: Target) {
    src +>:ProductDep:+> dst;
}

def add_dependency(src: Target, dst: Target, is_package_product: bool) {
    if is_package_product {
        src +>:ProductDep:+> dst;
    } else {
        src +>:ImmediateDep:+> dst;
    }
}

def compute_graph(start: Target) -> list[str] {
    init_visited: dict[str, bool] = {};
    init_result: list[str] = [];
    w = start spawn Discover(visited=init_visited, result=init_result);
    return w.result;
}

def transitive_closure(start: Target) -> list[str] {
    return compute_graph(start);
}

def reachable_tids(start: Target) -> list[str] {
    return compute_graph(start);
}

with entry {
    demo = Target(tid="demo");
    root ++> demo;
    dep = Target(tid="dep");
    root ++> dep;
    demo +>:ImmediateDep:+> dep;
    pkg = Target(tid="pkg");
    root ++> pkg;
    demo +>:ProductDep:+> pkg;
    w = demo spawn Discover(visited={}, result=[]);
    print(w.result);
}
