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
