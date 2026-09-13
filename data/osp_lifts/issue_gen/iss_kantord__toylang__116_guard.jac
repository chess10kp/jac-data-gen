node Graph { has gid: str; }
node EnumNode { has name: str; }
edge Contains {}
edge Dep {}

walker DfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can seed with Graph entry {
        for nd in [here ->:Contains:->][?:EnumNode] {
            visit [nd];
        }
    }
    can step with EnumNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        print(here.name);
        for nxt in [here ->:Dep:->][?:EnumNode] {
            visit :0: [nxt];
        }
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can step with EnumNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.out.append(here.name);
        print(here.name);
        for nxt in [here ->:Dep:->][?:EnumNode] {
            visit [nxt];
        }
    }
}

def new_graph(gid: str) -> Graph {
    g: Graph = Graph(gid=gid);
    root ++> g;
    return g;
}

def add_enum(g: Graph, name: str) -> EnumNode {
    nd: EnumNode = EnumNode(name=name);
    g +>:Contains:+> nd;
    return nd;
}

def add_dep(g: Graph, src: str, dst: str) {
    src_list: list[EnumNode] = [];
    dst_list: list[EnumNode] = [];
    for nd in [g ->:Contains:->][?:EnumNode] {
        if nd.name == src { src_list.append(nd); }
        if nd.name == dst { dst_list.append(nd); }
    }
    if len(src_list) == 0 { return; }
    if len(dst_list) == 0 { return; }
    s: EnumNode = src_list[0];
    d: EnumNode = dst_list[0];
    s +>:Dep:+> d;
}

def printers(g: Graph) -> list[str] {
    w: DfsWalk = g spawn DfsWalk(claimed={}, order=[]);
    res: list[str] = [];
    for n in w.order {
        res.append("def tl_show_" + n);
    }
    for r in res { print(r); }
    return res;
}

def ordered(g: Graph) -> list[str] {
    nodes: list[EnumNode] = [g ->:Contains:->][?:EnumNode];
    indeg: dict[str, int] = {};
    adj: dict[str, list[str]] = {};
    for nd in nodes {
        indeg[nd.name] = 0;
        empty: list[str] = [];
        adj[nd.name] = empty;
    }
    for nd in nodes {
        for dst in [nd ->:Dep:->][?:EnumNode] {
            if dst.name in indeg {
                adj[nd.name].append(dst.name);
                indeg[dst.name] = indeg[dst.name] + 1;
            }
        }
    }
    q: list[str] = [];
    for k in indeg {
        if indeg[k] == 0 { q.append(k); }
    }
    q = sorted(q);
    res: list[str] = [];
    while len(q) > 0 {
        cur: str = q[0];
        tmp: list[str] = [];
        idx: int = 0;
        for item in q {
            if idx != 0 { tmp.append(item); }
            idx = idx + 1;
        }
        q = tmp;
        res.append(cur);
        for nb in adj[cur] {
            indeg[nb] = indeg[nb] - 1;
            if indeg[nb] == 0 { q.append(nb); }
        }
        q = sorted(q);
    }
    if len(res) != len(nodes) {
        print("cycle refused");
        empty_ret: list[str] = [];
        return empty_ret;
    }
    out: list[str] = [];
    for n in res {
        out.append("def tl_show_" + n);
    }
    for s in out { print(s); }
    return out;
}

def reachable(g: Graph, start: str) -> list[str] {
    start_list: list[EnumNode] = [];
    for nd in [g ->:Contains:->][?:EnumNode] {
        if nd.name == start { start_list.append(nd); }
    }
    if len(start_list) == 0 {
        empty: list[str] = [];
        return empty;
    }
    s: EnumNode = start_list[0];
    w: ReachWalk = s spawn ReachWalk(claimed={}, out=[]);
    return w.out;
}

test "diamond_adversarial_revisit" {
    g: Graph = new_graph("diamond_adv");
    add_enum(g, "A"); add_enum(g, "C"); add_enum(g, "B"); add_enum(g, "D");
    add_dep(g, "A", "C"); add_dep(g, "A", "B"); add_dep(g, "C", "D"); add_dep(g, "B", "D");
    res: list[str] = ordered(g);
    assert(len(res) == 4);
    assert(res[0] == "def tl_show_A");
    assert(res[3] == "def tl_show_D");
    pos: dict[str, int] = {};
    idx: int = 0;
    for r in res { pos[r] = idx; idx = idx + 1; }
    assert(pos["def tl_show_A"] < pos["def tl_show_B"]);
    assert(pos["def tl_show_A"] < pos["def tl_show_C"]);
    assert(pos["def tl_show_B"] < pos["def tl_show_D"]);
    assert(pos["def tl_show_C"] < pos["def tl_show_D"]);
    r2: list[str] = reachable(g, "A");
    assert(len(r2) == 4);
    rs: list[str] = sorted(r2);
    assert(rs[0] == "A"); assert(rs[3] == "D");
}

test "mutual_cycle_refused" {
    g: Graph = new_graph("mutual_cycle");
    add_enum(g, "A"); add_enum(g, "B");
    add_dep(g, "A", "B"); add_dep(g, "B", "A");
    res: list[str] = ordered(g);
    assert(len(res) == 0);
    r2: list[str] = printers(g);
    assert(len(r2) == 2);
}

test "unknown_id_tolerance" {
    g: Graph = new_graph("unknown_tol");
    add_enum(g, "A");
    add_dep(g, "A", "Z");
    add_dep(g, "Z", "A");
    add_dep(g, "X", "Y");
    res: list[str] = ordered(g);
    assert(len(res) == 1);
    assert(res[0] == "def tl_show_A");
    r2: list[str] = reachable(g, "Z");
    assert(len(r2) == 0);
    r3: list[str] = reachable(g, "UNKNOWN");
    assert(len(r3) == 0);
}

test "self_cycle_and_empty" {
    g: Graph = new_graph("empty_case");
    res: list[str] = ordered(g);
    assert(len(res) == 0);
    g2: Graph = new_graph("self_cycle");
    add_enum(g2, "X");
    add_dep(g2, "X", "X");
    res2: list[str] = ordered(g2);
    assert(len(res2) == 0);
    r3: list[str] = reachable(g2, "X");
    assert(len(r3) == 1);
    assert(r3[0] == "X");
}
