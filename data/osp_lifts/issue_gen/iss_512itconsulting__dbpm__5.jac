node GraphRoot { has name: str; }
node Package {
    has app_name: str;
    has pkg_version: str;
    has installed_version: str = "";
    has installed_status: str = "";
}

edge Depends {}
edge Contains {}

walker PlanWalker {
    has claimed: dict[str, bool] = {};
    has db_available: bool = false;
    has dry_run: bool = false;
    has execution_order: list[str] = [];
    has satisfied: list[str] = [];

    can traverse with Package entry {
        if here.app_name in self.claimed { skip; }
        self.claimed[here.app_name] = true;
        print(here.app_name);
        deps: list[Package] = [here ->:Depends:->][?:Package];
        to_visit: list[Package] = [];
        for d in deps {
            if d.app_name not in self.claimed {
                to_visit.append(d);
            }
        }
        # decide satisfied vs install using installed state when db available
        should_install: bool = true;
        if self.db_available {
            if here.installed_version != "" and here.installed_status == "C" and here.installed_version == here.pkg_version {
                should_install = false;
            }
        }
        if should_install {
            self.execution_order.append(here.app_name);
        } else {
            self.satisfied.append(here.app_name);
        }
        if len(to_visit) > 0 {
            visit :0: to_visit;
        } else {
            disengage;
        }
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has reachable: list[str] = [];

    can step with Package entry {
        if here.app_name in self.claimed { skip; }
        self.claimed[here.app_name] = true;
        print(here.app_name);
        self.reachable.append(here.app_name);
        kids: list[Package] = [here ->:Depends:->][?:Package];
        to_visit: list[Package] = [];
        for k in kids {
            if k.app_name not in self.claimed {
                to_visit.append(k);
            }
        }
        if len(to_visit) > 0 {
            visit :0: to_visit;
        } else {
            disengage;
        }
    }
}

def make_graph -> GraphRoot {
    g: GraphRoot = GraphRoot(name="root");
    root ++> g;
    return g;
}

def find_package(graph_root: GraphRoot, app_name: str) -> Package | None {
    cands: list[Package] = [graph_root -->][?:Package];
    for c in cands {
        if c.app_name == app_name {
            return c;
        }
    }
    return None;
}

def add_package(graph_root: GraphRoot, app_name: str, pkg_version: str) -> Package {
    p: Package = Package(app_name=app_name, pkg_version=pkg_version);
    graph_root ++> p;
    return p;
}

def set_installed_state(pkg: Package, version: str, deploy_status: str) {
    pkg.installed_version = version;
    pkg.installed_status = deploy_status;
}

def add_dependency(from_pkg: Package, to_pkg: Package) {
    from_pkg +>:Depends:+> to_pkg;
}

def plan_install(graph_root: GraphRoot, root_name: str, db_available: bool, dry_run: bool) -> dict[str, list[str]] {
    pkg: Package | None = find_package(graph_root, root_name);
    if pkg is None {
        empty_exec: list[str] = [];
        empty_sat: list[str] = [];
        return {"execution_order": empty_exec, "satisfied_dependencies": empty_sat};
    }
    w: PlanWalker = pkg spawn PlanWalker(db_available=db_available, dry_run=dry_run);
    return {"execution_order": w.execution_order, "satisfied_dependencies": w.satisfied};
}

def get_reachable(graph_root: GraphRoot, start_name: str) -> list[str] {
    pkg: Package | None = find_package(graph_root, start_name);
    if pkg is None {
        empty: list[str] = [];
        return empty;
    }
    w: ReachWalker = pkg spawn ReachWalker();
    return w.reachable;
}

with entry {
    g: GraphRoot = make_graph();
    d: Package = add_package(g, "DEMO", "0.1.0");
    root spawn ReachWalker();
    print("demo entry");
}
