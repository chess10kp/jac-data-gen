node Pkg {
    has name: str;
    has version: str;
    has installed_version: str = "";
    has installed_status: str = "";
    has constraint: str = "";
}

edge Depends {}

walker PlanWalker {
    has claimed: dict[str, bool] = {};
    has execution_order: list[str] = [];
    has satisfied: list[str] = [];
    has satisfied_pkgs: list[Pkg] = [];
    has query_installed: bool = True;

    can step with Pkg entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        deps: list[Pkg] = [here ->:Depends:->][?:Pkg];
        for dep in deps {
            visit :0: [dep];
        }
        is_sat: bool = False;
        if self.query_installed {
            if here.installed_version != "" {
                if here.installed_status == "C" {
                    if here.constraint != "" {
                        if here.constraint == here.installed_version {
                            is_sat = True;
                        } else {
                            if here.constraint[0] == "^" {
                                stripped: str = here.constraint[1:];
                                if stripped == here.installed_version {
                                    is_sat = True;
                                } else {
                                    exp_major: str = stripped.split(".")[0];
                                    inst_major: str = here.installed_version.split(".")[0];
                                    if exp_major == inst_major {
                                        is_sat = True;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if is_sat {
            self.satisfied.append(here.name);
            self.satisfied_pkgs.append(here);
        } else {
            self.execution_order.append(here.name);
        }
        print(here.name);
    }
}

def make_pkg(name: str, version: str) -> Pkg {
    p: Pkg = Pkg(name=name, version=version);
    return p;
}

def add_dep(parent: Pkg, child: Pkg, constraint: str) {
    child.constraint = constraint;
    parent +>:Depends:+> child;
}

def mark_installed(pkg: Pkg, version: str, status: str) {
    pkg.installed_version = version;
    pkg.installed_status = status;
}

def get_installed_state(pkg: Pkg) -> dict[str, str] | None {
    if pkg.installed_version == "" {
        return None;
    }
    out: dict[str, str] = {};
    out["version"] = pkg.installed_version;
    out["deploy_status"] = pkg.installed_status;
    return out;
}

def plan_install(root_pkg: Pkg, query_installed: bool) -> dict[str, any] {
    w: PlanWalker = root_pkg spawn PlanWalker(query_installed=query_installed);
    exec_sorted: list[str] = sorted(w.execution_order);
    satisfied_deps: list[dict[str, any]] = [];
    for pkg in w.satisfied_pkgs {
        entry: dict[str, any] = {};
        entry["application_name"] = pkg.name;
        st: dict[str, str] = {};
        st["version"] = pkg.installed_version;
        st["deploy_status"] = pkg.installed_status;
        entry["installed_state"] = st;
        satisfied_deps.append(entry);
    }
    res: dict[str, any] = {};
    res["execution_order"] = exec_sorted;
    res["satisfied_dependencies"] = satisfied_deps;
    res["installed_state_evaluated"] = query_installed;
    res["execution_order_is_provisional"] = query_installed is False;
    return res;
}

with entry {
    root spawn PlanWalker(query_installed=True);
    demo_root: Pkg = Pkg(name="UNIVERSAL_FILE_LOADER", version="1.0.0");
    dep: Pkg = Pkg(name="JOB_CONTROL", version="1.1.0");
    dep.constraint = "^1.1.0";
    demo_root +>:Depends:+> dep;
    root ++> demo_root;
    root ++> dep;
    w: PlanWalker = demo_root spawn PlanWalker(query_installed=True);
    print(w.execution_order);
}

test "dry_run_with_state_query_excludes_satisfied" {
    root_pkg: Pkg = make_pkg("UNIVERSAL_FILE_LOADER", "1.0.0");
    dep: Pkg = make_pkg("JOB_CONTROL", "1.1.0");
    add_dep(root_pkg, dep, "^1.1.0");
    mark_installed(dep, "1.1.0", "C");
    res: dict[str, any] = plan_install(root_pkg, True);
    assert(res["execution_order"] == ["UNIVERSAL_FILE_LOADER"]);
    assert(res["installed_state_evaluated"] is True);
    assert(res["execution_order_is_provisional"] is False);
    sdeps: list[dict[str, any]] = res["satisfied_dependencies"] as list[dict[str, any]];
    assert(len(sdeps) == 1);
    assert(sdeps[0]["application_name"] == "JOB_CONTROL");
}

test "dry_run_without_query_includes_all" {
    root_pkg: Pkg = make_pkg("UNIVERSAL_FILE_LOADER", "1.0.0");
    dep: Pkg = make_pkg("JOB_CONTROL", "1.1.0");
    add_dep(root_pkg, dep, "^1.1.0");
    mark_installed(dep, "1.1.0", "C");
    res: dict[str, any] = plan_install(root_pkg, False);
    exec_ord: list[str] = res["execution_order"] as list[str];
    assert(len(exec_ord) == 2);
    assert(sorted(exec_ord) == ["JOB_CONTROL", "UNIVERSAL_FILE_LOADER"]);
    assert(res["installed_state_evaluated"] is False);
    assert(res["execution_order_is_provisional"] is True);
}

test "diamond_revisit_visits_once" {
    root_pkg: Pkg = make_pkg("UNIVERSAL_FILE_LOADER", "1.0.0");
    a: Pkg = make_pkg("A", "1.0.0");
    b: Pkg = make_pkg("B", "1.0.0");
    c: Pkg = make_pkg("C", "1.0.0");
    d: Pkg = make_pkg("D", "1.0.0");
    add_dep(root_pkg, a, "^1.0.0");
    add_dep(a, b, "^1.0.0");
    add_dep(a, c, "^1.0.0");
    add_dep(b, d, "^1.0.0");
    add_dep(c, d, "^1.0.0");
    mark_installed(d, "1.0.0", "C");
    d.constraint = "^1.0.0";
    res: dict[str, any] = plan_install(root_pkg, True);
    exec_ord: list[str] = res["execution_order"] as list[str];
    assert("D" not in exec_ord);
    sdeps: list[dict[str, any]] = res["satisfied_dependencies"] as list[dict[str, any]];
    assert(len(sdeps) == 1);
    res2: dict[str, any] = plan_install(root_pkg, False);
    exec2: list[str] = res2["execution_order"] as list[str];
    assert(len(exec2) == 5);
    assert(sorted(exec2) == ["A", "B", "C", "D", "UNIVERSAL_FILE_LOADER"]);
}

test "unknown_id_and_missing_state_tolerance" {
    lonely: Pkg = make_pkg("LONELY", "9.9.9");
    assert(get_installed_state(lonely) is None);
    res: dict[str, any] = plan_install(lonely, True);
    assert(res["execution_order"] == ["LONELY"]);
    assert(len(res["satisfied_dependencies"] as list[dict[str, any]]) == 0);
    fake: Pkg = make_pkg("FAKE_DEP", "0.0.1");
    add_dep(lonely, fake, "^0.0.1");
    res2: dict[str, any] = plan_install(lonely, True);
    assert(sorted(res2["execution_order"] as list[str]) == ["FAKE_DEP", "LONELY"]);
}

test "cycle_does_not_deadlock_and_counts_once" {
    x: Pkg = make_pkg("X", "1.0.0");
    y: Pkg = make_pkg("Y", "1.0.0");
    add_dep(x, y, "^1.0.0");
    add_dep(y, x, "^1.0.0");
    res: dict[str, any] = plan_install(x, True);
    exec_ord: list[str] = res["execution_order"] as list[str];
    assert(sorted(exec_ord) == ["X", "Y"]);
    assert(len(exec_ord) == 2);
}
