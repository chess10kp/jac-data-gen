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

test "dry_run with db_available respects installed satisfied diamond adversarial" {
    g: GraphRoot = make_graph();
    root_pkg: Package = add_package(g, "UNIVERSAL_FILE_LOADER", "2.0.0");
    dep: Package = add_package(g, "JOB_CONTROL", "1.1.0");
    a: Package = add_package(g, "A", "1.0.0");
    b: Package = add_package(g, "B", "1.0.0");
    add_dependency(root_pkg, a);
    add_dependency(root_pkg, b);
    add_dependency(a, dep);
    add_dependency(b, dep);
    set_installed_state(dep, "1.1.0", "C");
    plan: dict[str, list[str]] = plan_install(g, "UNIVERSAL_FILE_LOADER", true, true);
    exec_order: list[str] = plan["execution_order"];
    sat: list[str] = plan["satisfied_dependencies"];
    assert("JOB_CONTROL" not in exec_order);
    assert("JOB_CONTROL" in sat);
    assert("UNIVERSAL_FILE_LOADER" in exec_order);
    assert(len(exec_order) == 3);
}

test "dry_run without db_available shows dependency as fresh install" {
    g: GraphRoot = make_graph();
    root_pkg: Package = add_package(g, "UNIVERSAL_FILE_LOADER", "2.0.0");
    dep: Package = add_package(g, "JOB_CONTROL", "1.1.0");
    add_dependency(root_pkg, dep);
    set_installed_state(dep, "1.1.0", "C");
    plan: dict[str, list[str]] = plan_install(g, "UNIVERSAL_FILE_LOADER", false, true);
    exec_order: list[str] = plan["execution_order"];
    sat: list[str] = plan["satisfied_dependencies"];
    assert("JOB_CONTROL" in exec_order);
    assert(len(sat) == 0);
}

test "unknown root tolerance returns empty plan" {
    g: GraphRoot = make_graph();
    p: Package = add_package(g, "JOB_CONTROL", "1.1.0");
    plan: dict[str, list[str]] = plan_install(g, "MISSING_APP", true, true);
    assert(len(plan["execution_order"]) == 0);
    assert(len(plan["satisfied_dependencies"]) == 0);
    reach: list[str] = get_reachable(g, "UNKNOWN");
    assert(len(reach) == 0);
}

test "cycle diamond does not duplicate and path reach closed" {
    g: GraphRoot = make_graph();
    a: Package = add_package(g, "A", "1.0.0");
    b: Package = add_package(g, "B", "1.0.0");
    c: Package = add_package(g, "C", "1.0.0");
    d: Package = add_package(g, "D", "1.0.0");
    add_dependency(a, b);
    add_dependency(a, c);
    add_dependency(b, d);
    add_dependency(c, d);
    add_dependency(d, b);
    reach: list[str] = get_reachable(g, "A");
    assert(len(reach) == 4);
    assert("A" in reach);
    assert("D" in reach);
    plan: dict[str, list[str]] = plan_install(g, "A", false, false);
    assert(len(plan["execution_order"]) == 4);
}

test "installed state not C still installs" {
    g: GraphRoot = make_graph();
    root_pkg: Package = add_package(g, "UNIVERSAL_FILE_LOADER", "1.0.0");
    dep: Package = add_package(g, "JOB_CONTROL", "1.1.0");
    add_dependency(root_pkg, dep);
    set_installed_state(dep, "1.1.0", "I");
    plan: dict[str, list[str]] = plan_install(g, "UNIVERSAL_FILE_LOADER", true, true);
    assert("JOB_CONTROL" in plan["execution_order"]);
    assert("JOB_CONTROL" not in plan["satisfied_dependencies"]);
}
