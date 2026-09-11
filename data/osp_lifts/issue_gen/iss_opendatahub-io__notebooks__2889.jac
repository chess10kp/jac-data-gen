"""Dependency lock closure validation — opendatahub-io/notebooks#2889."""

node Pkg {
    has name: str;
    has cid: str;
}

edge Dep {}

def build_graph(packages: list) -> dict[str, Pkg] {
    store: dict[str, Pkg] = {};
    for raw in packages {
        nm: str = raw["name"];
        nd = Pkg(name=nm, cid=nm);
        store[nm] = nd;
        root ++> nd;
    }
    for raw in packages {
        src_nm: str = raw["name"];
        src: Pkg = store[src_nm] as Pkg;
        deps_raw: list = [];
        if "deps" in raw {
            deps_raw = raw["deps"];
        }
        for dep_nm in deps_raw {
            if dep_nm in store {
                kid: Pkg = store[dep_nm] as Pkg;
                src +>:Dep:+> kid;
            }
        }
    }
    return store;
}

def parse_lock_packages(packages: list) -> dict[str, list[str]] {
    store: dict[str, Pkg] = build_graph(packages);
    keys: list[str] = [];
    for nm in store {
        keys.append(nm);
    }
    keys.sort();
    out: dict[str, list[str]] = {};
    for nm in keys {
        nd: Pkg = store[nm] as Pkg;
        deps: list[str] = [];
        for ch in [nd ->:Dep:->][?:Pkg] {
            deps.append(ch.name);
        }
        deps.sort();
        out[nm] = deps;
    }
    return out;
}

def missing_lock_dependencies(packages: list) -> list[list[str]] {
    locked: dict[str, bool] = {};
    for raw in packages {
        locked[raw["name"]] = True;
    }
    out: list[list[str]] = [];
    for raw in packages {
        src_nm: str = raw["name"];
        deps_raw: list = [];
        if "deps" in raw {
            deps_raw = raw["deps"];
        }
        for dep_nm in deps_raw {
            if dep_nm not in locked {
                row: list[str] = [src_nm, dep_nm];
                out.append(row);
            }
        }
    }
    out.sort();
    return out;
}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Pkg entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("walk " + here.name);
        self.order.append(here.name);
        kids: list[Pkg] = [];
        for ch in [here ->:Dep:->][?:Pkg] {
            kids.append(ch);
        }
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }
}

def walk_dependency_order(packages: list, start: str) -> list[str] {
    store: dict[str, Pkg] = build_graph(packages);
    if start not in store {
        return [];
    }
    start_nd: Pkg = store[start] as Pkg;
    w = start_nd spawn OrderWalker();
    return w.order;
}
