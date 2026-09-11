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
