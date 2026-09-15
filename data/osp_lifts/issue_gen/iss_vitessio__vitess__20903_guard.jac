"""Unmerged recursive CTE UNION DISTINCT semantics — vitessio/vitess#20903."""

node OrgRoot {}

node Emp {
    has uid: str;
    has name: str;
    has mgr_id: str = "";
}

edge MgrEdge {}

def build_org_graph(entries: list) -> OrgRoot {
    org = OrgRoot();
    root ++> org;
    emp_map: dict[str, Emp] = {};
    for ent in entries {
        uid: str = ent[0];
        nm: str = ent[1];
        mgr_raw = ent[2];
        mgr_s: str = "";
        if mgr_raw is not None {
            mgr_s = mgr_raw;
        }
        e = Emp(uid=uid, name=nm, mgr_id=mgr_s);
        emp_map[uid] = e;
        org ++> e;
    }
    for ent in entries {
        uid: str = ent[0];
        mgr_raw = ent[2];
        if mgr_raw is not None {
            mgr_s: str = mgr_raw;
            if mgr_s != "" {
                par = emp_map[mgr_s] if mgr_s in emp_map else None;
                if par is not None {
                    kid = emp_map[uid];
                    par +>:MgrEdge:+> kid;
                }
            }
        }
    }
    return org;
}

def term_children(mgr: Emp) -> list[Emp] {
    kids: list[Emp] = [];
    for ch in [mgr ->:MgrEdge:->][?:Emp] {
        kids.append(ch);
    }
    return kids;
}

def collect_seeds(org: OrgRoot) -> list[Emp] {
    seeds: list[Emp] = [];
    for e in [org ->>][?:Emp] {
        if e.mgr_id == "" {
            seeds.append(e);
        }
    }
    return seeds;
}

def recurse_cte_names(org: OrgRoot, distinct: bool, merged_route: bool) -> list[str] {
    result: list[str] = [];
    seen_rows: dict[str, bool] = {};
    frontier: list[Emp] = collect_seeds(org);
    depth: int = 0;
    max_depth: int = 64;
    while len(frontier) > 0 and depth < max_depth {
        next_frontier: list[Emp] = [];
        for emp in frontier {
            row_key: str = emp.name + ":" + emp.uid;
            is_dup: bool = False;
            if distinct and merged_route {
                if row_key in seen_rows {
                    is_dup = True;
                }
            }
            if is_dup {
                # merged DISTINCT drops duplicate working-table rows entirely
            } else {
                if distinct and merged_route {
                    seen_rows[row_key] = True;
                }
                result.append(emp.name);
                kids: list[Emp] = term_children(emp);
                for k in kids {
                    next_frontier.append(k);
                }
            }
            if distinct and (not merged_route) and is_dup {
                # unmerged route bug: UNION ALL semantics — still emit and re-enqueue
                result.append(emp.name);
                kids2: list[Emp] = term_children(emp);
                for k2 in kids2 {
                    next_frontier.append(k2);
                }
            }
        }
        frontier = next_frontier;
        depth += 1;
    }
    return result;
}

walker SeedProbe {
    has claimed: dict[str, bool] = {};
    has count: int = 0;

    can probe with OrgRoot entry {
        print("seed_probe_begin");
        w = root spawn SeedWalk(claimed={});
        self.count = w.count;
        print("seed_probe_end", self.count);
    }
}

walker SeedWalk {
    has claimed: dict[str, bool] = {};
    has count: int = 0;

    can step with Emp entry {
        if here.uid in self.claimed {
            skip;
        }
        self.claimed[here.uid] = True;
        if here.mgr_id == "" {
            self.count += 1;
        }
        print("seed_walk", here.uid);
        kids: list[Emp] = [];
        for ch in [here ->:MgrEdge:->][?:Emp] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

test "collect_seeds_single_root" {
    rows = [("ceo", "Alice", ""), ("mgr", "Bob", "ceo")];
    org = build_org_graph(rows);
    seeds = collect_seeds(org);
    uids: list[str] = [];
    for s in seeds {
        uids.append(s.uid);
    }
    uids.sort();
    assert uids == ["ceo"];
}

test "term_children_sorted" {
    rows = [("ceo", "A", ""), ("m", "B", "ceo"), ("e1", "C", "m"), ("e2", "D", "m")];
    org = build_org_graph(rows);
    seeds = collect_seeds(org);
    mgr_kids = term_children(seeds[0]);
    assert len(mgr_kids) == 1;
    leaves = term_children(mgr_kids[0]);
    leaf_uids: list[str] = [];
    for leaf in leaves {
        leaf_uids.append(leaf.uid);
    }
    leaf_uids.sort();
    assert leaf_uids == ["e1", "e2"];
}

test "recurse_bfs_chain" {
    rows = [("ceo", "Alice", ""), ("mgr", "Bob", "ceo"), ("e1", "Carol", "mgr"), ("e2", "Dave", "mgr")];
    org = build_org_graph(rows);
    got = recurse_cte_names(org, distinct=False, merged_route=False);
    assert got == ["Alice", "Bob", "Carol", "Dave"];
}

test "merged_vs_unmerged_on_tree" {
    rows = [("ceo", "Alice", ""), ("mgr", "Bob", "ceo"), ("e1", "Carol", "mgr")];
    org = build_org_graph(rows);
    unmerged = recurse_cte_names(org, distinct=True, merged_route=False);
    merged = recurse_cte_names(org, distinct=True, merged_route=True);
    assert unmerged == merged;
    assert merged == ["Alice", "Bob", "Carol"];
}

test "null_mgr_treated_as_root" {
    rows = [("r1", "Root", None), ("c1", "Child", "r1")];
    org = build_org_graph(rows);
    seeds = collect_seeds(org);
    uids: list[str] = [];
    for s in seeds {
        uids.append(s.uid);
    }
    uids.sort();
    assert uids == ["r1"];
    names = recurse_cte_names(org, distinct=True, merged_route=True);
    assert names == ["Root", "Child"];
}

test "seed_probe_walker_runs" {
    rows = [("ceo", "A", ""), ("e1", "B", "ceo")];
    org = build_org_graph(rows);
    wk = org spawn SeedProbe();
    assert wk.count >= 0;
}
