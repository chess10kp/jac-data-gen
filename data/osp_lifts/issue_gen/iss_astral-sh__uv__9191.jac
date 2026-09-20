"""astral-sh/uv#9191 — checksum-based local dependency freshness (Docker ctime workaround)."""

node Package {
    has pkg_id: str;
    has name: str;
    has installed_cs: str = "";
}

edge Depends {}

obj DepGraph {
    has store: dict[str, Package] = {};
}

def _spec_installed_cs(spec: dict) -> str {
    if "installed_cs" in spec {
        return str(spec["installed_cs"]);
    }
    return "";
}

def _spec_deps(spec: dict) -> list {
    if "deps" in spec {
        return spec["deps"];
    }
    empty_deps: list = [];
    return empty_deps;
}

def build_graph(specs: list[dict]) -> DepGraph {
    g = DepGraph();
    store: dict[str, Package] = {};
    for spec in specs {
        pid = str(spec["pkg_id"]);
        pkg = Package(
            pkg_id=pid,
            name=str(spec["name"]),
            installed_cs=_spec_installed_cs(spec)
        );
        store[pid] = pkg;
    }
    for spec in specs {
        pid = str(spec["pkg_id"]);
        src = store[pid] as Package;
        for dep_id in _spec_deps(spec) {
            dep_key = str(dep_id);
            if dep_key in store {
                dst = store[dep_key] as Package;
                src +>:Depends:+> dst;
            }
        }
    }
    for pid in store {
        root ++> store[pid] as Package;
    }
    g.store = store;
    return g;
}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has origin_id: str = "";
    has found: list[str] = [];

    can ascend with Package entry {
        if here.pkg_id in self.claimed {
            skip;
        }
        self.claimed[here.pkg_id] = True;
        print("ancestor", here.pkg_id);
        if here.pkg_id != self.origin_id {
            self.found.append(here.pkg_id);
        }
        ups: list[Package] = [];
        for dep in [here ->:Depends:->][?:Package] {
            ups.append(dep);
        }
        if len(ups) > 0 {
            visit :0: ups;
        }
    }
}

walker DependentWalker {
    has claimed: dict[str, bool] = {};
    has origin_id: str = "";
    has touched: list[str] = [];

    can descend with Package entry {
        if here.pkg_id in self.claimed {
            skip;
        }
        self.claimed[here.pkg_id] = True;
        print("cascade", here.pkg_id);
        self.touched.append(here.pkg_id);
        downs: list[Package] = [];
        for user in [here <-:Depends:<-][?:Package] {
            downs.append(user);
        }
        if len(downs) > 0 {
            visit :0: downs;
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};

    can step with Package entry {
        if here.pkg_id in self.claimed {
            skip;
        }
        self.claimed[here.pkg_id] = True;
        print("demo", here.pkg_id, here.installed_cs);
        kids: list[Package] = [];
        for dep in [here ->:Depends:->][?:Package] {
            kids.append(dep);
        }
        if len(kids) > 0 {
            visit :0: kids;
        }
    }
}

def memo_ancestors(g: DepGraph, pkg_id: str) -> list[str] {
    if pkg_id not in g.store {
        return [];
    }
    start = g.store[pkg_id] as Package;
    w = start spawn AncestorWalker(origin_id=pkg_id, claimed={}, found=[]);
    return sorted(w.found);
}

def cascade_invalidation(g: DepGraph, origin_id: str) -> list[str] {
    if origin_id not in g.store {
        return [];
    }
    start = g.store[origin_id] as Package;
    w = start spawn DependentWalker(origin_id=origin_id, claimed={}, touched=[]);
    return sorted(w.touched);
}

def stale_install_targets(g: DepGraph, manifest_checksums: dict[str, str]) -> list[str] {
    origins: list[str] = [];
    for pid in sorted(g.store) {
        if pid not in manifest_checksums {
            continue;
        }
        pkg = g.store[pid] as Package;
        if manifest_checksums[pid] != pkg.installed_cs {
            origins.append(pid);
        }
    }
    marked: dict[str, bool] = {};
    for origin in origins {
        part = cascade_invalidation(g, origin);
        for sid in part {
            marked[sid] = True;
        }
    }
    out: list[str] = [];
    for pid in sorted(marked) {
        out.append(pid);
    }
    return out;
}

with entry {
    demo_specs: list[dict] = [
        {"pkg_id": "api", "name": "api", "deps": ["lib"], "installed_cs": "a1"},
        {"pkg_id": "lib", "name": "lib", "deps": [], "installed_cs": "l0"}
    ];
    g = build_graph(demo_specs);
    cs: dict[str, str] = {"lib": "l1"};
    targets = stale_install_targets(g, cs);
    print("stale_targets", targets);
    root spawn DemoWalker(claimed={});
}
