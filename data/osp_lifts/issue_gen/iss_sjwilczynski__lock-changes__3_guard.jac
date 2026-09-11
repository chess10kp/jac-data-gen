node Pkg {
    has name: str;
    has version: str;
    has pid: str;
    has is_root: bool = false;
}

edge Depends {}

walker CollectAll {
    has claimed: dict[str, bool] = {};
    has nodes: list[Pkg] = [];
    can collect with Pkg entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.nodes.append(here);
        print(here.pid);
        nxt: list[Pkg] = [];
        for ch in [here ->:Depends:->][?:Pkg] {
            nxt.append(ch);
        }
        if nxt {
            visit nxt;
        } else {
            disengage;
        }
    }
}

walker ProvenanceWalker {
    has target: str = "";
    has cap: int = 2;
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has out: dict[str, list[list[str]]] = {};
    can walk with Pkg entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.path.append(here.pid);
        print(here.pid);
        if here.name == self.target {
            ver: str = here.version;
            if ver not in self.out {
                self.out[ver] = [];
            }
            cur: list[list[str]] = self.out[ver];
            if len(cur) < self.cap {
                cp: list[str] = [];
                for p in self.path {
                    cp.append(p);
                }
                cur.append(cp);
            }
        }
        nxt: list[Pkg] = [];
        for ch in [here ->:Depends:->][?:Pkg] {
            nxt.append(ch);
        }
        if nxt {
            visit nxt;
        } else {
            disengage;
        }
    }
}

def make_pkg(name: str, version: str, pid: str, is_root: bool) -> Pkg {
    return Pkg(name=name, version=version, pid=pid, is_root=is_root);
}

def add_dep(parent: Pkg, child: Pkg) {
    parent +>:Depends:+> child;
}

def duplicate_provenance(graph_root: Pkg, cap: int) -> dict[str, dict[str, list[list[str]]]] {
    ca = graph_root spawn CollectAll();
    groups: dict[str, list[Pkg]] = {};
    vers: dict[str, dict[str, bool]] = {};
    for nd in ca.nodes {
        if nd.name not in groups {
            groups[nd.name] = [];
            vers[nd.name] = {};
        }
        groups[nd.name].append(nd);
        vers[nd.name][nd.version] = True;
    }
    out: dict[str, dict[str, list[list[str]]]] = {};
    for nm in groups {
        vmap: dict[str, bool] = vers[nm];
        cnt: int = len(vmap);
        if cnt > 1 {
            pw = graph_root spawn ProvenanceWalker(target=nm, cap=cap);
            out[nm] = pw.out;
        }
    }
    return out;
}

with entry {
    demo_root: Pkg = Pkg(name="__root__", version="0.0.0", pid="__root__", is_root=True);
    root ++> demo_root;
    a: Pkg = make_pkg("lru-cache", "10.4.3", "lru-cache@10.4.3", False);
    b: Pkg = make_pkg("lru-cache", "6.0.0", "lru-cache@6.0.0", False);
    mid: Pkg = make_pkg("cacache", "1.0.0", "cacache", False);
    root ++> a;
    root ++> b;
    root ++> mid;
    add_dep(demo_root, mid);
    add_dep(mid, a);
    add_dep(demo_root, b);
    w = demo_root spawn ProvenanceWalker(target="lru-cache", cap=2);
    print(w.out);
    root spawn CollectAll();
    print("demo done");
}

test "diamond revisit both chains via shared intermediate" {
    r: Pkg = Pkg(name="__root__", version="0.0.0", pid="r", is_root=True);
    root ++> r;
    a: Pkg = make_pkg("mid-a", "1.0.0", "a", False);
    b: Pkg = make_pkg("mid-b", "1.0.0", "b", False);
    c: Pkg = make_pkg("lru-cache", "10.4.3", "c10", False);
    d: Pkg = make_pkg("lru-cache", "6.0.0", "c6", False);
    root ++> a; root ++> b; root ++> c; root ++> d;
    add_dep(r, a);
    add_dep(r, b);
    add_dep(a, c);
    add_dep(b, c);
    add_dep(r, d);
    res: dict[str, dict[str, list[list[str]]]] = duplicate_provenance(r, 5);
    assert("lru-cache" in res);
    chains10: list[list[str]] = res["lru-cache"]["10.4.3"];
    assert(len(chains10) == 2);
    # normalize chains to sorted string for order-insensitive check
    s0: str = chains10[0][0] + chains10[0][1] + chains10[0][2];
    s1: str = chains10[1][0] + chains10[1][1] + chains10[1][2];
    assert((s0 == "rac10" and s1 == "rbc10") or (s0 == "rbc10" and s1 == "rac10"));
    chains6: list[list[str]] = res["lru-cache"]["6.0.0"];
    assert(len(chains6) == 1);
    assert(chains6[0][0] == "r");
    assert(chains6[0][1] == "c6");
}

test "cycle handled without infinite loop" {
    r: Pkg = Pkg(name="__root__", version="0.0.0", pid="r2", is_root=True);
    root ++> r;
    x: Pkg = make_pkg("lru-cache", "10.4.3", "x10", False);
    y: Pkg = make_pkg("lru-cache", "6.0.0", "y6", False);
    m: Pkg = make_pkg("loop", "1.0.0", "m", False);
    root ++> x; root ++> y; root ++> m;
    add_dep(r, m);
    add_dep(m, x);
    add_dep(x, m);
    add_dep(r, y);
    res: dict[str, dict[str, list[list[str]]]] = duplicate_provenance(r, 3);
    assert("lru-cache" in res);
    assert(len(res["lru-cache"]["10.4.3"]) >= 1);
    assert(len(res["lru-cache"]["6.0.0"]) == 1);
}

test "cap limits chains per version" {
    r: Pkg = Pkg(name="__root__", version="0.0.0", pid="r3", is_root=True);
    root ++> r;
    p1: Pkg = make_pkg("p", "1.0.0", "p1", False);
    p2: Pkg = make_pkg("p", "1.0.0", "p2", False);
    p3: Pkg = make_pkg("p", "1.0.0", "p3", False);
    v: Pkg = make_pkg("dup", "1.0.0", "v1", False);
    v2: Pkg = make_pkg("dup", "2.0.0", "v2", False);
    root ++> p1; root ++> p2; root ++> p3; root ++> v; root ++> v2;
    add_dep(r, p1); add_dep(r, p2); add_dep(r, p3);
    add_dep(p1, v); add_dep(p2, v); add_dep(p3, v);
    add_dep(r, v2);
    res1: dict[str, dict[str, list[list[str]]]] = duplicate_provenance(r, 2);
    assert(len(res1["dup"]["1.0.0"]) == 2);
    res2: dict[str, dict[str, list[list[str]]]] = duplicate_provenance(r, 5);
    assert(len(res2["dup"]["1.0.0"]) == 3);
}

test "unknown package not duplicated returns empty" {
    r: Pkg = Pkg(name="__root__", version="0.0.0", pid="r4", is_root=True);
    root ++> r;
    a: Pkg = make_pkg("single", "1.0.0", "s1", False);
    b: Pkg = make_pkg("single", "1.0.0", "s2", False);
    root ++> a; root ++> b;
    add_dep(r, a);
    add_dep(r, b);
    res: dict[str, dict[str, list[list[str]]]] = duplicate_provenance(r, 3);
    assert(not ("single" in res));
    assert(len(res) == 0);
}

test "adversarial order diamond still finds both chains" {
    r: Pkg = Pkg(name="__root__", version="0.0.0", pid="r5", is_root=True);
    root ++> r;
    # insertion order: b first then a, so revisit of c fires before deeper first-visit would
    b: Pkg = make_pkg("mid-b", "1.0.0", "b5", False);
    a: Pkg = make_pkg("mid-a", "1.0.0", "a5", False);
    c: Pkg = make_pkg("lru-cache", "9.0.0", "c9", False);
    d: Pkg = make_pkg("lru-cache", "8.0.0", "c8", False);
    root ++> b; root ++> a; root ++> c; root ++> d;
    add_dep(r, b);
    add_dep(r, a);
    add_dep(b, c);
    add_dep(a, c);
    add_dep(r, d);
    res: dict[str, dict[str, list[list[str]]]] = duplicate_provenance(r, 10);
    assert("lru-cache" in res);
    assert(len(res["lru-cache"]["9.0.0"]) == 2);
}
