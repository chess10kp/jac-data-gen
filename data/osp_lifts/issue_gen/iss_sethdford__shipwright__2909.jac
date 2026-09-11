node RepoRoot { has path: str; has writable: bool; has has_merge_conflict: bool; }
node ToolCheck { has cid: str; has command: str; has executable: bool; }
node DepCheck { has cid: str; has lockfile_present: bool; has deps_resolvable: bool; }
edge CheckLink {}
edge Depends {}

walker CollectChecks {
    has claimed: dict[str, bool] = {};
    has tools: list[ToolCheck] = [];
    has deps: list[DepCheck] = [];
    can start with RepoRoot entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        print(here.path);
        for tc in [here ->:CheckLink:->][?:ToolCheck] {
            visit [tc];
        }
        for dc in [here ->:CheckLink:->][?:DepCheck] {
            visit [dc];
        }
    }
    can handle_tool with ToolCheck entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.tools.append(here);
        print(here.cid);
        for nxt in [here ->:Depends:->][?:ToolCheck] {
            visit [nxt];
        }
        for nxt2 in [here ->:Depends:->][?:DepCheck] {
            visit [nxt2];
        }
    }
    can handle_dep with DepCheck entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.deps.append(here);
        print(here.cid);
        for nxt in [here ->:Depends:->][?:ToolCheck] {
            visit [nxt];
        }
        for nxt2 in [here ->:Depends:->][?:DepCheck] {
            visit [nxt2];
        }
    }
}

def make_repo(path: str, writable: bool, has_merge_conflict: bool) -> RepoRoot {
    nd: RepoRoot = RepoRoot(path=path, writable=writable, has_merge_conflict=has_merge_conflict);
    return nd;
}

def add_tool_check(graph_root: RepoRoot, cid: str, command: str, executable: bool) -> ToolCheck {
    tc: ToolCheck = ToolCheck(cid=cid, command=command, executable=executable);
    graph_root +>:CheckLink:+> tc;
    return tc;
}

def add_dep_check(graph_root: RepoRoot, cid: str, lockfile_present: bool, deps_resolvable: bool) -> DepCheck {
    dc: DepCheck = DepCheck(cid=cid, lockfile_present=lockfile_present, deps_resolvable=deps_resolvable);
    graph_root +>:CheckLink:+> dc;
    return dc;
}

def add_dependency(graph_root: RepoRoot, from_cid: str, to_cid: str) -> bool {
    col: CollectChecks = graph_root spawn CollectChecks(claimed={});
    from_tool: ToolCheck | None = None;
    from_dep: DepCheck | None = None;
    to_tool: ToolCheck | None = None;
    to_dep: DepCheck | None = None;
    for t in col.tools {
        if t.cid == from_cid { from_tool = t; }
        if t.cid == to_cid { to_tool = t; }
    }
    for d in col.deps {
        if d.cid == from_cid { from_dep = d; }
        if d.cid == to_cid { to_dep = d; }
    }
    if from_tool is not None {
        if to_tool is not None {
            from_tool +>:Depends:+> to_tool;
            return True;
        }
        if to_dep is not None {
            from_tool +>:Depends:+> to_dep;
            return True;
        }
    }
    if from_dep is not None {
        if to_tool is not None {
            from_dep +>:Depends:+> to_tool;
            return True;
        }
        if to_dep is not None {
            from_dep +>:Depends:+> to_dep;
            return True;
        }
    }
    return False;
}

def pre_build_validate(graph_root: RepoRoot) -> dict[str, str] {
    result: dict[str, str] = {};
    if graph_root.path == "" {
        result["repo_path"] = "repo path missing or empty";
    } elif graph_root.writable == False {
        result["repo_path"] = "repo path not writable";
    } else {
        result["repo_path"] = "ok";
    }
    if graph_root.has_merge_conflict {
        result["merge_conflict"] = "uncommitted merge conflicts present";
    } else {
        result["merge_conflict"] = "ok";
    }
    col: CollectChecks = graph_root spawn CollectChecks(claimed={});
    for t in col.tools {
        if t.command == "" {
            result[t.cid] = "test command missing";
        } elif t.executable == False {
            result[t.cid] = "test command not executable: " + t.command;
        } else {
            result[t.cid] = "ok";
        }
    }
    for d in col.deps {
        if d.lockfile_present == False {
            result[d.cid] = "lockfile missing";
        } elif d.deps_resolvable == False {
            result[d.cid] = "deps not resolvable";
        } else {
            result[d.cid] = "ok";
        }
    }
    print("validate done");
    return result;
}

def pipeline_entry(graph_root: RepoRoot) -> dict[str, str] {
    res: dict[str, str] = pre_build_validate(graph_root);
    print("pipeline entry");
    return res;
}

with entry {
    demo_root: RepoRoot = RepoRoot(path="/tmp", writable=True, has_merge_conflict=False);
    demo_root spawn CollectChecks(claimed={});
    print("demo");
}
