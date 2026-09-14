node FailureReason {
    has code: str;
}

node Run {
    has run_id: str;
    has worker_id: str;
    has phase: str = "running";
    has payload: str = "";
    has delivery: str = "none";
    has delivery_claimed: bool = False;
    has execution_count: int = 1;
    has delivery_retries: int = 0;
    has max_delivery_retries: int = 3;
    has failure_reason: FailureReason | None = None;
}

node Task {
    has task_id: str;
    has title: str;
    has status: str = "queued";
    has progress: int = 0;
    has attempts: int = 0;
}

edge Depends {}

node Orchestrator {
    has runs: dict[str, Run] = {};
    has tasks: dict[str, Task] = {};
}

walker DeliveryWalker {
    has claimed: dict[str, bool] = {};
    has ui_state: str = "";

    can reconcile with Run entry {
        if here.run_id in self.claimed { skip; }
        self.claimed[here.run_id] = True;
        if here.delivery == "delivered" {
            self.ui_state = "ready";
        } elif here.delivery == "delivery_failed" or here.delivery == "result_stored" {
            self.ui_state = "recoverable";
        } elif here.delivery == "delivery_pending" {
            self.ui_state = "waiting_delivery";
        } else {
            self.ui_state = "active";
        }
        print(self.ui_state);
    }
}

walker DependencyWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.found.append(here.task_id);
        print(here.task_id);
        for kid in [here ->:Depends:->][?:Task] {
            visit :0: [kid];
        }
    }
}

def new_orchestrator() -> Orchestrator {
    return Orchestrator();
}

def find_run(store: Orchestrator, run_id: str) -> Run | None {
    if run_id in store.runs { return store.runs[run_id]; }
    return None;
}

def start_run(store: Orchestrator, run_id: str, worker_id: str) -> Run {
    existing = find_run(store, run_id);
    if existing is not None { return existing; }
    run_node = Run(run_id=run_id, worker_id=worker_id);
    store.runs[run_id] = run_node;
    store ++> run_node;
    return run_node;
}

def complete_run(store: Orchestrator, run_id: str, payload: str) -> str {
    run_node = find_run(store, run_id);
    if run_node is None { return "unknown"; }
    if run_node.phase == "completed" { return run_node.delivery; }
    run_node.payload = payload;
    run_node.phase = "completed";
    run_node.delivery = "result_stored";
    run_node.failure_reason = None;
    return run_node.delivery;
}

def request_delivery(store: Orchestrator, run_id: str) -> str {
    run_node = find_run(store, run_id);
    if run_node is None { return "unknown"; }
    if run_node.delivery != "result_stored" { return "not_ready"; }
    run_node.delivery = "delivery_pending";
    return run_node.delivery;
}

def claim_delivery(store: Orchestrator, run_id: str) -> bool {
    run_node = find_run(store, run_id);
    if run_node is None or run_node.delivery != "delivery_pending" {
        return False;
    }
    if run_node.delivery_claimed { return False; }
    run_node.delivery_claimed = True;
    return True;
}

def settle_delivery(store: Orchestrator, run_id: str, delivered: bool,
                    reason: FailureReason | None = None) -> str {
    run_node = find_run(store, run_id);
    if run_node is None { return "unknown"; }
    if not run_node.delivery_claimed { return "not_claimed"; }
    run_node.delivery_claimed = False;
    if delivered {
        run_node.delivery = "delivered";
        run_node.failure_reason = None;
    } else {
        run_node.delivery = "delivery_failed";
        if reason is None {
            run_node.failure_reason = FailureReason(code="delivery_unavailable");
        } else {
            run_node.failure_reason = reason;
        }
    }
    return run_node.delivery;
}

def retry_delivery(store: Orchestrator, run_id: str) -> bool {
    run_node = find_run(store, run_id);
    if run_node is None or run_node.delivery != "delivery_failed" {
        return False;
    }
    if run_node.failure_reason is None or
        run_node.failure_reason.code != "delivery_unavailable" {
        return False;
    }
    if run_node.delivery_retries >= run_node.max_delivery_retries {
        return False;
    }
    run_node.delivery_retries += 1;
    run_node.delivery = "delivery_pending";
    return True;
}

def reconcile_activity(store: Orchestrator, run_id: str) -> str {
    run_node = find_run(store, run_id);
    if run_node is None { return "unknown"; }
    w = run_node spawn DeliveryWalker(claimed={}, ui_state="");
    return w.ui_state;
}

def failure_code(store: Orchestrator, run_id: str) -> str {
    run_node = find_run(store, run_id);
    if run_node is None or run_node.failure_reason is None { return ""; }
    return run_node.failure_reason.code;
}

def find_task(store: Orchestrator, task_id: str) -> Task | None {
    if task_id in store.tasks { return store.tasks[task_id]; }
    return None;
}

def add_task(store: Orchestrator, task_id: str, title: str) -> Task {
    existing = find_task(store, task_id);
    if existing is not None { return existing; }
    task_node = Task(task_id=task_id, title=title);
    store.tasks[task_id] = task_node;
    store ++> task_node;
    return task_node;
}

def add_dependency(store: Orchestrator, parent_id: str, child_id: str) -> bool {
    parent_node = find_task(store, parent_id);
    child_node = find_task(store, child_id);
    if parent_node is None or child_node is None { return False; }
    parent_node +>:Depends:+> child_node;
    return True;
}

def dependency_closure(store: Orchestrator, task_id: str) -> list[str] {
    task_node = find_task(store, task_id);
    if task_node is None { return []; }
    w = task_node spawn DependencyWalker(claimed={}, found=[]);
    return sorted(w.found);
}

test "durable completion retries delivery without rerunning work" {
    store = new_orchestrator();
    run_node = start_run(store, "run-1", "audit-bot");
    assert (complete_run(store, "run-1", "audit summary") == "result_stored");
    assert (request_delivery(store, "run-1") == "delivery_pending");
    assert (claim_delivery(store, "run-1") == True);
    assert (settle_delivery(store, "run-1", False,
        FailureReason(code="delivery_unavailable")) == "delivery_failed");
    assert (run_node.payload == "audit summary");
    assert (failure_code(store, "run-1") == "delivery_unavailable");
    assert (reconcile_activity(store, "run-1") == "recoverable");
    assert (retry_delivery(store, "run-1") == True);
    assert (claim_delivery(store, "run-1") == True);
    assert (settle_delivery(store, "run-1", True) == "delivered");
    assert (run_node.execution_count == 1);
    assert (reconcile_activity(store, "run-1") == "ready");
}

test "unknown identifiers are tolerated" {
    store = new_orchestrator();
    assert (find_run(store, "missing") is None);
    assert (complete_run(store, "missing", "ignored") == "unknown");
    assert (request_delivery(store, "missing") == "unknown");
    assert (claim_delivery(store, "missing") == False);
    assert (settle_delivery(store, "missing", True) == "unknown");
    assert (reconcile_activity(store, "missing") == "unknown");
    assert (add_dependency(store, "missing", "also-missing") == False);
    assert (dependency_closure(store, "missing") == []);
}

test "diamond dependencies and cycles are visited once" {
    store = new_orchestrator();
    add_task(store, "a", "lead");
    add_task(store, "b", "left");
    add_task(store, "c", "right");
    add_task(store, "d", "shared");
    assert (add_dependency(store, "a", "b") == True);
    assert (add_dependency(store, "a", "c") == True);
    assert (add_dependency(store, "b", "d") == True);
    assert (add_dependency(store, "c", "d") == True);
    assert (add_dependency(store, "d", "a") == True);
    found = dependency_closure(store, "a");
    assert (found == ["a", "b", "c", "d"]);
}
