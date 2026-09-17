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
