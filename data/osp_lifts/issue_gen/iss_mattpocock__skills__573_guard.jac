"""Recursive /code-review fan-out guard — mattpocock/skills#573."""

node Invoker {
    has iid: str;
    has skill: str;
    has root_owned: bool = False;
}

node Boot {
    has label: str = "skills573";
}

edge Delegates {}

walker TraverseWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has blocked: int = 0;

    can step with Invoker entry {
        if here.iid in self.claimed {
            if here.skill == "code-review" {
                self.blocked += 1;
            }
            skip;
        }
        self.claimed[here.iid] = True;
        self.order.append(here.iid);
        kids: list[Invoker] = [];
        for ch in [here ->:Delegates:->][?:Invoker] {
            kids.append(ch);
        }
        visit :0: kids else { disengage; }
    }
}

walker DemoWalk {
    can show with Boot entry {
        print("skills573 code-review fanout guard");
        disengage;
    }
}

def build_review_mesh(specs: list[list[str]]) -> object {
    nodes: dict[str, Invoker] = {};
    for row in specs {
        pid = row[0];
        cid = row[1];
        skill = row[2];
        if pid not in nodes {
            pn = Invoker(iid=pid, skill="orchestrator", root_owned=False);
            nodes[pid] = pn;
            root ++> pn;
        }
        if cid not in nodes {
            cn = Invoker(iid=cid, skill=skill, root_owned=False);
            nodes[cid] = cn;
            root ++> cn;
        } else {
            cn = nodes[cid];
            cn.skill = skill;
        }
        par = nodes[pid];
        chn = nodes[cid];
        par +>:Delegates:+> chn;
    }
    store: dict[str, object] = {};
    store["nodes"] = nodes;
    return store;
}

def mark_root(mesh: object, root_iid: str) -> None {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if root_iid not in nodes {
        return;
    }
    rn = nodes[root_iid];
    rn.skill = "code-review";
    rn.root_owned = True;
}

def traverse_invocations(mesh: object, start_iid: str) -> list[str] {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if start_iid not in nodes {
        return [];
    }
    start = nodes[start_iid];
    w = start spawn TraverseWalk(claimed={});
    return w.order;
}

def blocked_reinvokes(mesh: object, start_iid: str) -> int {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if start_iid not in nodes {
        return 0;
    }
    start = nodes[start_iid];
    w = start spawn TraverseWalk(claimed={});
    return w.blocked;
}

def allowed_fanout(mesh: object, root_iid: str) -> list[str] {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if root_iid not in nodes {
        return [];
    }
    root_nd = nodes[root_iid];
    if not root_nd.root_owned {
        return [];
    }
    ids: list[str] = [];
    for ch in [root_nd ->:Delegates:->][?:Invoker] {
        if ch.skill == "standards" or ch.skill == "spec" {
            ids.append(ch.iid);
        }
    }
    return sorted(ids);
}

def may_invoke_review(mesh: object, actor_iid: str, skill: str) -> bool {
    if skill != "code-review" {
        return True;
    }
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if actor_iid not in nodes {
        return False;
    }
    actor = nodes[actor_iid];
    return actor.root_owned;
}

with entry {
    boot = Boot();
    root ++> boot;
    boot spawn DemoWalk();
}

"""Recursive /code-review fan-out guard — mattpocock/skills#573."""

node Invoker {
    has iid: str;
    has skill: str;
    has root_owned: bool = False;
}

node Boot {
    has label: str = "skills573";
}

edge Delegates {}

walker TraverseWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has blocked: int = 0;

    can step with Invoker entry {
        if here.iid in self.claimed {
            if here.skill == "code-review" {
                self.blocked += 1;
            }
            skip;
        }
        self.claimed[here.iid] = True;
        self.order.append(here.iid);
        kids: list[Invoker] = [];
        for ch in [here ->:Delegates:->][?:Invoker] {
            kids.append(ch);
        }
        visit :0: kids else { disengage; }
    }
}

walker DemoWalk {
    can show with Boot entry {
        print("skills573 code-review fanout guard");
        disengage;
    }
}

def build_review_mesh(specs: list[list[str]]) -> object {
    nodes: dict[str, Invoker] = {};
    for row in specs {
        pid = row[0];
        cid = row[1];
        skill = row[2];
        if pid not in nodes {
            pn = Invoker(iid=pid, skill="orchestrator", root_owned=False);
            nodes[pid] = pn;
            root ++> pn;
        }
        if cid not in nodes {
            cn = Invoker(iid=cid, skill=skill, root_owned=False);
            nodes[cid] = cn;
            root ++> cn;
        } else {
            cn = nodes[cid];
            cn.skill = skill;
        }
        par = nodes[pid];
        chn = nodes[cid];
        par +>:Delegates:+> chn;
    }
    store: dict[str, object] = {};
    store["nodes"] = nodes;
    return store;
}

def mark_root(mesh: object, root_iid: str) -> None {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if root_iid not in nodes {
        return;
    }
    rn = nodes[root_iid];
    rn.skill = "code-review";
    rn.root_owned = True;
}

def traverse_invocations(mesh: object, start_iid: str) -> list[str] {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if start_iid not in nodes {
        return [];
    }
    start = nodes[start_iid];
    w = start spawn TraverseWalk(claimed={});
    return w.order;
}

def blocked_reinvokes(mesh: object, start_iid: str) -> int {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if start_iid not in nodes {
        return 0;
    }
    start = nodes[start_iid];
    w = start spawn TraverseWalk(claimed={});
    return w.blocked;
}

def allowed_fanout(mesh: object, root_iid: str) -> list[str] {
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if root_iid not in nodes {
        return [];
    }
    root_nd = nodes[root_iid];
    if not root_nd.root_owned {
        return [];
    }
    ids: list[str] = [];
    for ch in [root_nd ->:Delegates:->][?:Invoker] {
        if ch.skill == "standards" or ch.skill == "spec" {
            ids.append(ch.iid);
        }
    }
    return sorted(ids);
}

def may_invoke_review(mesh: object, actor_iid: str, skill: str) -> bool {
    if skill != "code-review" {
        return True;
    }
    store = mesh as dict[str, object];
    nodes = store["nodes"] as dict[str, Invoker];
    if actor_iid not in nodes {
        return False;
    }
    actor = nodes[actor_iid];
    return actor.root_owned;
}

with entry {
    boot = Boot();
    root ++> boot;
    boot spawn DemoWalk();
}

test "traverse_dfs_first_visits" {
    specs: list[list[str]] = [
        ["r", "a", "code-review"],
        ["r", "s", "standards"],
        ["a", "b", "code-review"],
    ];
    mesh = build_review_mesh(specs);
    mark_root(mesh, "r");
    got = traverse_invocations(mesh, "r");
    assert got == ["r", "a", "b", "s"];
}

test "blocked_on_cycle_revisit" {
    specs: list[list[str]] = [
        ["r", "a", "code-review"],
        ["a", "b", "code-review"],
        ["b", "a", "code-review"],
    ];
    mesh = build_review_mesh(specs);
    mark_root(mesh, "r");
    assert blocked_reinvokes(mesh, "r") == 1;
}

test "allowed_fanout_sorted" {
    specs: list[list[str]] = [
        ["r", "p", "spec"],
        ["r", "s", "standards"],
        ["r", "x", "code-review"],
    ];
    mesh = build_review_mesh(specs);
    mark_root(mesh, "r");
    assert allowed_fanout(mesh, "r") == ["p", "s"];
}

test "may_invoke_review_root_only" {
    specs: list[list[str]] = [
        ["r", "a", "code-review"],
    ];
    mesh = build_review_mesh(specs);
    mark_root(mesh, "r");
    assert may_invoke_review(mesh, "r", "code-review") == True;
    assert may_invoke_review(mesh, "a", "code-review") == False;
    assert may_invoke_review(mesh, "a", "standards") == True;
}

test "unknown_ids_tolerated" {
    specs: list[list[str]] = [
        ["r", "a", "code-review"],
    ];
    mesh = build_review_mesh(specs);
    assert traverse_invocations(mesh, "missing") == [];
    assert blocked_reinvokes(mesh, "missing") == 0;
    assert allowed_fanout(mesh, "missing") == [];
    assert may_invoke_review(mesh, "missing", "code-review") == False;
}

test "fanout_requires_root_owned" {
    specs: list[list[str]] = [
        ["r", "s", "standards"],
    ];
    mesh = build_review_mesh(specs);
    assert allowed_fanout(mesh, "r") == [];
}
