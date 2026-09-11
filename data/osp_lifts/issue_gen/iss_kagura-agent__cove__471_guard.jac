"""Guard: kagura-agent/cove#471."""

node TaskNode {
    has tid: str;
    has status: str = "open";
}

edge DependsOn {}

obj WorkflowBoard {
    has tasks: dict[str, TaskNode] = {};
}

walker DependentCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with TaskNode entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        visit [->:DependsOn:->][?:TaskNode];
    }
}

def load_workflow(
    tasks: list[str],
    deps: list[tuple[str, str]],
) -> WorkflowBoard {
    b = WorkflowBoard();
    for tid in tasks {
        nd = TaskNode(tid=tid);
        root ++> nd;
        b.tasks[tid] = nd;
    }
    for (blocker, task) in deps {
        blk = b.tasks.get(blocker, None);
        tgt = b.tasks.get(task, None);
        if blk is not None and tgt is not None { blk +>:DependsOn:+> tgt; }
    }
    return b;
}

def ready_tasks(board: WorkflowBoard) -> list[str] {
    ready: list[str] = [];
    for (tid, nd) in board.tasks.items() {
        if nd.status != "open" { continue; }
        blocked = False;
        for blk in [nd <-:DependsOn:<-][?:TaskNode] {
            if blk.status != "done" { blocked = True; }
        }
        if not blocked { ready.append(tid); }
    }
    return sorted(ready);
}

def mark_failed(board: WorkflowBoard, task_id: str) -> list[str] {
    nd = board.tasks.get(task_id, None);
    if nd is None { return []; }
    nd.status = "failed";
    w = nd spawn DependentCollect(claimed={}, found=[]);
    skipped: list[str] = [];
    for tid in w.found {
        if tid == task_id { continue; }
        tgt = board.tasks.get(tid, None);
        if tgt is not None and tgt.status == "open" {
            tgt.status = "skipped";
            skipped.append(tid);
        }
    }
    return sorted(skipped);
}

def mark_done(board: WorkflowBoard, task_id: str) {
    nd = board.tasks.get(task_id, None);
    if nd is not None { nd.status = "done"; }
}

test "workflow ready progression" {
    b = load_workflow(
        ["collect", "analyze", "debate", "decide"],
        [("collect", "analyze"), ("analyze", "debate"), ("debate", "decide")],
    );
    assert ready_tasks(b) == ["collect"];
    mark_done(b, "collect");
    assert ready_tasks(b) == ["analyze"];
}

test "cascade skip on failure" {
    b = load_workflow(
        ["setup", "integration", "report"],
        [("setup", "integration"), ("integration", "report")],
    );
    assert mark_failed(b, "setup") == ["integration", "report"];
}

test "diamond fan-in ready" {
    b = load_workflow(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
    );
    assert ready_tasks(b) == ["hub"];
    mark_done(b, "hub");
    assert ready_tasks(b) == ["left", "right"];
}
