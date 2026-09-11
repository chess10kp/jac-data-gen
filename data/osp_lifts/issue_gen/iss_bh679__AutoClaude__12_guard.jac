"""Task queue with dependency gating, lifted to OSP.

Tasks become Task nodes; dependency declarations become typed DependsOn
edges (task -> its dependency). Eligibility gating reads the edges
directly, the dashboard's transitive dependents query becomes a walker
over the reverse edge direction, and the cycle guard for
create/update becomes a claim-map probe that must not reach the task
from itself. The queue handle is a loader obj; ids resolve through its
lookup map.
Ref: bh679/AutoClaude#12
"""
node Task {
    has name: str;
    has approved: bool = True;
    has done: bool = False;
}
edge DependsOn {}

"""Queue handle: task ids resolve through this lookup map."""
obj Queue {
    has tasks: dict[str, Task];

    def resolve(name: str) -> Task | None {
        return self.tasks.get(name);
    }
}

"""Fresh task queue."""
def new_queue() -> Queue {
    return Queue(tasks={});
}

def add_task(queue: Queue, task_id: str, deps: list[str] = [], approved: bool = True) -> Queue {
    if task_id in queue.tasks {
        raise ValueError(f"duplicate task {task_id}");
    }
    for d in deps {
        if d == task_id {
            raise ValueError(f"task {task_id} cannot depend on itself");  # CircularDependencyError
        }
        if d not in queue.tasks {
            raise KeyError(f"unknown dependency {d}");
        }
    }
    t = Task(name=task_id, approved=approved, done=False);
    root ++> t;
    queue.tasks[task_id] = t;
    for d in deps {
        t +>:DependsOn:+> queue.tasks[d];
    }
    return queue;
}

def update_task(queue: Queue, task_id: str, deps: list[str]) -> Queue {
    t = queue.resolve(task_id);
    if t is None {
        raise KeyError(f"unknown task {task_id}");
    }
    for d in deps {
        if d == task_id {
            raise ValueError(f"task {task_id} cannot depend on itself");  # CircularDependencyError
        }
        if d not in queue.tasks {
            raise KeyError(f"unknown dependency {d}");
        }
    }
    # Rewire, probe for a self-reachable cycle, revert on rejection.
    old: list[Task] = [];
    for d in [t->:DependsOn:->] {
        dt: Task = d;
        old.append(dt);
    }
    for d in old {
        t del ->:DependsOn:-> d;
    }
    for d in deps {
        t +>:DependsOn:+> queue.tasks[d];
    }
    # Cycle probe: task must not be reachable from any of its new deps.
    cyclic = False;
    for d in deps {
        w = queue.tasks[d] spawn ReachWalk(claimed={});
        if task_id in w.reached {
            cyclic = True;
        }
    }
    if cyclic {
        for d in [t->:DependsOn:->] {
            dt: Task = d;
            t del ->:DependsOn:-> dt;
        }
        for d in old {
            t +>:DependsOn:+> d;
        }
        raise ValueError(f"dependency cycle through {task_id}");  # CircularDependencyError
    }
    return queue;
}

def complete_task(queue: Queue, task_id: str) -> str | None {
    t = queue.resolve(task_id);
    if t is None {
        return None;
    }
    t.done = True;
    return task_id;
}

def get_next_approved(queue: Queue) -> str | None {
    for tid in sorted(queue.tasks.keys()) {
        t = queue.tasks[tid];
        if t.approved and not t.done {
            ready = True;
            for d in [t->:DependsOn:->] {
                dt: Task = d;
                if not dt.done {
                    ready = False;
                }
            }
            if ready {
                return tid;
            }
        }
    }
    return None;
}

def waiting_for(queue: Queue, task_id: str) -> list[str] {
    t = queue.resolve(task_id);
    if t is None {
        return [];
    }
    pending: list[str] = [];
    for d in [t->:DependsOn:->] {
        dt: Task = d;
        if not dt.done {
            pending.append(dt.name);
        }
    }
    return sorted(pending);
}

walker DependentsWalk {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Task entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.members.append(here.name);
        visit [<-:DependsOn:<-];  # reverse direction: who depends on me
    }
}

def dependents(queue: Queue, task_id: str) -> list[str] {
    t = queue.resolve(task_id);
    if t is None {
        return [];
    }
    w = t spawn DependentsWalk(claimed={});
    names = [n for n in w.members if n != task_id];
    return sorted(names);
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: dict[str, bool] = {};

    can step with Task entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.reached[here.name] = True;
        visit [->:DependsOn:->] else { disengage; }
    }
}

test "dependency gating and dashboard queries" {
    q = new_queue();
    add_task(q, "a");
    add_task(q, "b", deps=["a"]);
    add_task(q, "c", deps=["b", "a"]);
    assert get_next_approved(q) == "a";
    assert waiting_for(q, "c") == ["a", "b"];
    assert dependents(q, "a") == ["b", "c"];
    assert dependents(q, "c") == [];
}

test "unknown dependency and duplicate rejected" {
    q = new_queue();
    add_task(q, "a");
    raised = False;
    try {
        add_task(q, "d", deps=["zzz"]);
    } except KeyError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        add_task(q, "a");
    } except ValueError {
        raised = True;
    }
    assert raised;
}

test "self-dependency rejected at creation" {
    q = new_queue();
    raised = False;
    try {
        add_task(q, "e", deps=["e"]);
    } except ValueError {
        raised = True;
    }
    assert raised;
}

test "transitive cycle closed via update rejected, state preserved" {
    q = new_queue();
    add_task(q, "x");
    add_task(q, "y", deps=["x"]);
    add_task(q, "z", deps=["y"]);
    raised = False;
    try {
        update_task(q, "x", deps=["z"]);
    } except ValueError {
        raised = True;
    }
    assert raised;
    assert waiting_for(q, "x") == [];
    assert dependents(q, "x") == ["y", "z"];
    raised = False;
    try {
        update_task(q, "x", deps=["ghost"]);
    } except KeyError {
        raised = True;
    }
    assert raised;
    update_task(q, "z", deps=["x"]);
    assert waiting_for(q, "z") == ["x"];
}

test "completion flows through the chain" {
    q = new_queue();
    add_task(q, "a");
    add_task(q, "b", deps=["a"]);
    add_task(q, "c", deps=["b", "a"]);
    assert complete_task(q, "a") == "a";
    assert get_next_approved(q) == "b";
    assert waiting_for(q, "b") == [];
    assert waiting_for(q, "c") == ["b"];
    complete_task(q, "b");
    assert get_next_approved(q) == "c";
    assert complete_task(q, "nobody") == None;
    complete_task(q, "c");
    assert get_next_approved(q) == None;
}

test "diamond dependencies dedup in dependents walk" {
    q = new_queue();
    add_task(q, "base");
    add_task(q, "l", deps=["base"]);
    add_task(q, "r", deps=["base"]);
    add_task(q, "top", deps=["l", "r"]);
    assert dependents(q, "base") == ["l", "r", "top"];
    complete_task(q, "base");
    assert waiting_for(q, "l") == [];
    assert get_next_approved(q) == "l";
}
