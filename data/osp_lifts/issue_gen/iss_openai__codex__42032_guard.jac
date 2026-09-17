# openai/codex#42032 — runaway recursive subagent tree: bounded delegation
# budget, descendant counting, and cascading cancellation (claim-map cycles).

node AgentTask {
    has aid: str;
    has budget: int = 1;
    has status: str = "running";
}

edge Delegates {}

walker Spawner {
    has claimed: dict[str, bool] = {};
    can spawn_step with AgentTask entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        if here.budget > 0 and here.status == "running" {
            kid: AgentTask = AgentTask(aid=here.aid + ".c" + str(len(self.claimed)), budget=here.budget - 1);
            here +>:Delegates:+> kid;
            visit [kid];
        }
    }
}

walker CountTree {
    has claimed: dict[str, bool] = {};
    can count_step with AgentTask entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        visit [here ->:Delegates:->][?:AgentTask];
    }
}

walker CancelTree {
    has claimed: dict[str, bool] = {};
    has cancelled: list[str] = [];
    can cancel_step with AgentTask entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        here.status = "cancelled";
        self.cancelled.append(here.aid);
        visit [here ->:Delegates:->][?:AgentTask];
    }
}

# Launch a review tree: budget bounds total descendants per branch.
def spawn_review_tree(coordinator: AgentTask, budget: int) -> int {
    coordinator.budget = budget;
    wk = coordinator spawn Spawner(claimed={});
    return len(wk.claimed);
}

# Count every agent reachable from root, diamonds counted once.
def count_descendants(root: AgentTask) -> int {
    wk = root spawn CountTree(claimed={});
    return len(wk.claimed);
}

# Emergency stop: cancel the whole descendant tree, return sorted ids.
def cancel_descendant_tree(root: AgentTask) -> list[str] {
    wk = root spawn CancelTree(claimed={});
    return sorted(wk.cancelled);
}

# Manual delegation: refused when parent exhausted or already cancelled.
def create_descendant(parent: AgentTask, aid: str) -> AgentTask | None {
    if parent.budget <= 0 or parent.status != "running" {
        return None;
    }
    parent.budget = parent.budget - 1;
    kid: AgentTask = AgentTask(aid=aid, budget=parent.budget);
    parent +>:Delegates:+> kid;
    return kid;
}

test "diamond counted once under adversarial order" {
    a = AgentTask(aid="a", budget=0);
    b = AgentTask(aid="b", budget=0);
    c = AgentTask(aid="c", budget=0);
    d = AgentTask(aid="d", budget=0);
    a +>:Delegates:+> b;
    a +>:Delegates:+> c;
    c +>:Delegates:+> d;
    b +>:Delegates:+> d;
    assert (count_descendants(a) == 4);
}

test "cascading cancel stops runaway tree" {
    root = AgentTask(aid="coord", budget=1);
    spawn_review_tree(root, 1);
    assert (count_descendants(root) >= 2);
    cancelled = cancel_descendant_tree(root);
    assert (cancelled == sorted(cancelled));
    assert (len(cancelled) == count_descendants(root));
    assert (root.status == "cancelled");
}

test "delegation budget caps recursion" {
    root = AgentTask(aid="cap", budget=0);
    n = spawn_review_tree(root, 1);
    assert (n <= 2);
    assert (count_descendants(root) == n);
}

test "orphan prevention after cancel" {
    p = AgentTask(aid="p", budget=2);
    cancel_descendant_tree(p);
    assert (create_descendant(p, "x") == None);
    q = AgentTask(aid="q", budget=1);
    kid = create_descendant(q, "kid1");
    assert (kid != None and kid.status == "running");
    assert (create_descendant(q, "kid2") != None);
    assert (create_descendant(q, "kid3") == None);
}

test "empty tree and unknown-id tolerance" {
    solo = AgentTask(aid="solo", budget=0);
    assert (count_descendants(solo) == 1);
    assert (cancel_descendant_tree(solo) == ["solo"]);
    assert (spawn_review_tree(solo, 5) == 1);
}
