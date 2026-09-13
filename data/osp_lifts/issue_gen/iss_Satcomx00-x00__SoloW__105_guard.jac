node AgentProfile {
    has pid: str;
    has coordinator: bool = False;
}

node Task {
    has task_id: str;
    has title: str;
    has root_id: str = "";
    has depth: int = 0;
    has state: str = "pending";
    has reviewed: bool = False;
    has changes: int = 0;
}

edge Child {}
edge Depends {}
edge Assigned {}
edge Message {}

walker TaskTreeWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has states: list[str] = [];

    can step with Task entry {
        if here.task_id in self.claimed {
            skip;
        }
        self.claimed[here.task_id] = True;
        self.found.append(here.task_id);
        self.states.append(here.task_id + ":" + here.state);
        print(here.task_id);
        for kid in [here ->:Child:->][?:Task] {
            visit :0: [kid];
        }
    }
}

def delegation_scope(profile: AgentProfile) -> list[str] {
    scopes: list[str] = [];
    if profile.coordinator {
        scopes.append("create_subtasks");
        scopes.append("message_siblings");
    } else {
        scopes.append("execute_task");
    }
    return scopes;
}

def contains_task(root_node: Task, target_id: str) -> bool {
    w = root_node spawn TaskTreeWalker(claimed={});
    if target_id in w.found {
        return True;
    }
    return False;
}

def delegation_tree(root_node: Task) -> list[str] {
    w = root_node spawn TaskTreeWalker(claimed={});
    return w.states;
}

def delegate(
    profile: AgentProfile,
    root_node: Task,
    parent: Task,
    child: Task,
    max_depth: int,
    max_total: int
) -> bool {
    if profile.coordinator == False {
        return False;
    }
    if contains_task(root_node, parent.task_id) == False {
        return False;
    }
    if contains_task(root_node, child.task_id) {
        return False;
    }
    if parent.depth >= max_depth {
        return False;
    }

    w = root_node spawn TaskTreeWalker(claimed={});
    if len(w.found) - 1 >= max_total {
        return False;
    }

    if root_node.root_id == "" {
        root_node.root_id = root_node.task_id;
    }
    child.root_id = root_node.task_id;
    child.depth = parent.depth + 1;
    parent +>:Child:+> child;
    return True;
}

def dependencies_ready(task: Task) -> bool {
    for dependency in [task ->:Depends:->][?:Task] {
        if dependency.state != "done" {
            return False;
        }
    }
    return True;
}

def review_gate(task: Task) -> bool {
    if task.changes > 0 {
        return task.reviewed;
    }
    return True;
}

test "coordinator scope and review gate" {
    coordinator = AgentProfile(pid="coord", coordinator=True);
    worker = AgentProfile(pid="worker");

    assert (delegation_scope(coordinator) == ["create_subtasks", "message_siblings"]);
    assert (delegation_scope(worker) == ["execute_task"]);

    plan = Task(task_id="plan", title="plan");
    dependency = Task(task_id="dep", title="dependency");
    plan +>:Depends:+> dependency;

    assert (dependencies_ready(plan) == False);
    dependency.state = "done";
    assert (dependencies_ready(plan) == True);

    plan.changes = 1;
    assert (review_gate(plan) == False);
    plan.reviewed = True;
    assert (review_gate(plan) == True);
}

test "diamond revisit and unknown task tolerance" {
    graph_root = Task(task_id="r", title="root");
    left = Task(task_id="a", title="left");
    right = Task(task_id="b", title="right");
    shared = Task(task_id="c", title="shared");

    graph_root +>:Child:+> left;
    graph_root +>:Child:+> right;
    left +>:Child:+> shared;
    right +>:Child:+> shared;

    states: list[str] = delegation_tree(graph_root);
    assert (len(states) == 4);
    assert (sorted(states) == [
        "a:pending",
        "b:pending",
        "c:pending",
        "r:pending"
    ]);
    assert (contains_task(graph_root, "missing") == False);
}

test "depth and volume bounds" {
    coordinator = AgentProfile(pid="coord", coordinator=True);
    worker = AgentProfile(pid="worker");
    graph_root = Task(task_id="r", title="root");
    first = Task(task_id="a", title="first");
    second = Task(task_id="b", title="second");
    deep = Task(task_id="c", title="deep");

    assert (delegate(worker, graph_root, graph_root, first, 2, 3) == False);
    assert (delegate(coordinator, graph_root, graph_root, first, 1, 1) == True);
    assert (delegate(coordinator, graph_root, graph_root, second, 1, 1) == False);
    assert (delegate(coordinator, graph_root, first, deep, 1, 3) == False);
    assert (len(delegation_tree(graph_root)) == 2);
}
