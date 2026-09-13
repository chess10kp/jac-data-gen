node Project {
    has pid: str;
    has dir_path: str;
}
edge Depends {}

walker CollectClosure {
    has claimed: dict[str, bool] = {};
    has closure: list[str] = [];
    can collect with Project entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.closure.append(here.pid);
        print(here.pid);
        kids: list[Project] = [here ->:Depends:->][?:Project];
        for k in kids {
            visit :0: [k];
        }
    }
}

walker Show {
    has dummy: bool = True;
    can show with Project entry {
        print(here.pid);
    }
}

def discover_workspaces(literal_paths: list[str], parent_star_patterns: list[str], all_dirs: list[str]) -> list[str] {
    # fast paths: literal exact match and parent/* one-level without wax glob
    seen: dict[str, bool] = {};
    out: list[str] = [];
    for d in all_dirs {
        is_lit: bool = False;
        for lit in literal_paths {
            if d == lit { is_lit = True; }
        }
        if is_lit {
            if d not in seen { seen[d] = True; out.append(d); }
            continue;
        }
        for pat in parent_star_patterns {
            if len(pat) >= 2 {
                pref: str = pat[0: len(pat) - 2];
                if len(d) > len(pref) {
                    if d[0: len(pref)] == pref {
                        if d[len(pref)] == "/" {
                            rest: str = d[len(pref) + 1:];
                            has_slash: bool = False;
                            for c in rest { if c == "/" { has_slash = True; } }
                            if has_slash == False {
                                if d not in seen { seen[d] = True; out.append(d); }
                            }
                        }
                    }
                }
            }
        }
    }
    return sorted(out);
}

def resolve_workspace_deps(project_names: list[str], dep_pairs: list[list[str]]) -> dict[str, list[str]] {
    store: dict[str, Project] = {};
    for pid in project_names {
        nd: Project = Project(pid=pid, dir_path=pid);
        root ++> nd;
        store[pid] = nd;
    }
    for pair in dep_pairs {
        if len(pair) >= 2 {
            a: str = pair[0]; b: str = pair[1];
            if a in store { if b in store {
                sa: Project = store[a]; sb: Project = store[b];
                sa +>:Depends:+> sb;
            } }
        }
    }
    shared: dict[str, list[str]] = {};
    result: dict[str, list[str]] = {};
    for pid in project_names {
        if pid in store {
            if pid in shared { result[pid] = shared[pid]; }
            else {
                st: Project = store[pid];
                w: CollectClosure = st spawn CollectClosure(claimed={}, closure=[]);
                deps: list[str] = [];
                for cid in w.closure { if cid != pid { deps.append(cid); } }
                deps = sorted(deps);
                shared[pid] = deps;
                result[pid] = deps;
            }
        }
    }
    return result;
}

def get_transitive_deps(project_names: list[str], dep_pairs: list[list[str]], start_id: str) -> list[str] {
    store: dict[str, Project] = {};
    for pid in project_names {
        nd: Project = Project(pid=pid, dir_path=pid);
        root ++> nd;
        store[pid] = nd;
    }
    for pair in dep_pairs {
        if len(pair) >= 2 {
            a: str = pair[0]; b: str = pair[1];
            if a in store { if b in store {
                sa: Project = store[a]; sb: Project = store[b];
                sa +>:Depends:+> sb;
            } }
        }
    }
    if start_id not in store { return []; }
    st: Project = store[start_id];
    w: CollectClosure = st spawn CollectClosure(claimed={}, closure=[]);
    out: list[str] = [];
    for cid in w.closure { if cid != start_id { out.append(cid); } }
    return sorted(out);
}

with entry {
    demo: Project = Project(pid="demo", dir_path="demo");
    root ++> demo;
    w: CollectClosure = demo spawn CollectClosure(claimed={}, closure=[]);
    print(w.closure);
    root spawn Show(dummy=True);
}
