# iss_EnterOS-AI__enter-os-core__2256.jac

node Task {
    has task_id: str;
    has skill_id: str;
    has adapter_name: str;
    has status: str = "queued";
    has ceiling_secs: int = 0;
    has cleanup_grace_secs: int = 30;
    has started_at: int = 0;
    has completed_at: int = 0;
    has graph_depth: int = 0;
}

node Audit {
    has event_type: str;
    has task_id: str;
    has skill_id: str;
    has adapter_name: str;
    has status: str;
    has started_at: int = 0;
    has completed_at: int = 0;
    has ceiling_secs_at_start: int = 0;
    has termination_reason: str = "";
    has terminator_workspace_id: str = "";
    has propagation_attempts: int = 0;
    has orphan_descendants: int = 0;
    has graph_depth: int = 0;
    has total_propagation_secs: int = 0;
}

node Platform {
    has tasks: dict[str, Task] = {};
    has cleanup_grace: dict[str, int] = {};
    has audits: list[Audit] = [];
    has sync_limit_secs: int = 900;
    has async_limit_secs: int = 86400;
}

edge Owns {}
edge Delegates {}
edge Records {}

walker Descendants {
    has origin: str;
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        print(here.task_id);
        if here.task_id != self.origin {
            self.found.append(here.task_id);
        }
        for child in [here ->:Delegates:->][?:Task] {
            visit :0: [child];
        }
    }
}

def new_platform(sync_limit: int = 900, async_limit: int = 86400) -> Platform {
    return Platform(sync_limit_secs=sync_limit, async_limit_secs=async_limit);
}

def configure_adapter(platform: Platform, adapter_name: str, grace_secs: int) -> bool {
    if grace_secs < 0 { return False; }
    platform.cleanup_grace[adapter_name] = grace_secs;
    return True;
}

def register_task(
    platform: Platform,
    task_id: str,
    skill_id: str,
    adapter_name: str,
    ceiling_secs: int,
    async_mode: bool
) -> bool {
    if task_id in platform.tasks { return False; }
    if ceiling_secs <= 0 { return False; }
    if async_mode and ceiling_secs > platform.async_limit_secs { return False; }
    if not async_mode and ceiling_secs > platform.sync_limit_secs { return False; }

    grace: int = 30;
    if adapter_name in platform.cleanup_grace {
        grace = platform.cleanup_grace[adapter_name];
    }
    task = Task(
        task_id=task_id,
        skill_id=skill_id,
        adapter_name=adapter_name,
        ceiling_secs=ceiling_secs,
        cleanup_grace_secs=grace
    );
    platform.tasks[task_id] = task;
    platform +>:Owns:+> task;
    return True;
}

def link_delegation(platform: Platform, parent_id: str, child_id: str) -> bool {
    if parent_id not in platform.tasks { return False; }
    if child_id not in platform.tasks { return False; }
    parent = platform.tasks[parent_id];
    child = platform.tasks[child_id];
    if child.graph_depth < parent.graph_depth + 1 {
        child.graph_depth = parent.graph_depth + 1;
    }
    parent +>:Delegates:+> child;
    return True;
}

def _emit(
    platform: Platform,
    task: Task,
    event_type: str,
    status: str
) -> None {
    event = Audit(
        event_type=event_type,
        task_id=task.task_id,
        skill_id=task.skill_id,
        adapter_name=task.adapter_name,
        status=status,
        started_at=task.started_at,
        completed_at=task.completed_at,
        ceiling_secs_at_start=task.ceiling_secs
    );
    platform.audits.append(event);
    platform +>:Records:+> event;
}

def start_task(platform: Platform, task_id: str, started_at: int) -> bool {
    if task_id not in platform.tasks { return False; }
    task = platform.tasks[task_id];
    if task.status != "queued" { return False; }
    task.status = "running";
    task.started_at = started_at;
    _emit(platform, task, "task_executed", "started");
    return True;
}

def finish_task(
    platform: Platform,
    task_id: str,
    status: str,
    completed_at: int
) -> bool {
    if task_id not in platform.tasks { return False; }
    if status not in ["completed", "failed", "abandoned"] { return False; }
    task = platform.tasks[task_id];
    if task.status != "running" { return False; }
    task.status = status;
    task.completed_at = completed_at;
    _emit(platform, task, "task_executed", status);
    return True;
}

def terminate_task(
    platform: Platform,
    task_id: str,
    workspace_id: str,
    completed_at: int
) -> list[str] {
    if task_id not in platform.tasks { return []; }
    parent = platform.tasks[task_id];
    if parent.status != "queued" and parent.status != "running" { return []; }

    descendants: list[str] = [];
    claimed: dict[str, bool] = {};
    w = parent spawn Descendants(
        origin=task_id,
        found=descendants,
        claimed=claimed
    );

    terminated: list[str] = [];
    for descendant_id in descendants {
        child = platform.tasks[descendant_id];
        if child.status == "queued" or child.status == "running" {
            child.status = "terminated";
            child.completed_at = completed_at;
            _emit(platform, child, "task_terminated", "terminated");
            terminated.append(descendant_id);
        }
    }

    parent.status = "terminated";
    parent.completed_at = completed_at;
    _emit(platform, parent, "task_terminated", "terminated");
    last: Audit = platform.audits[len(platform.audits) - 1];
    last.termination_reason = "operator_ceiling";
    last.terminator_workspace_id = workspace_id;
    last.propagation_attempts = 3;
    last.orphan_descendants = len(terminated);
    last.graph_depth = parent.graph_depth;
    last.total_propagation_secs = parent.cleanup_grace_secs;
    return terminated;
}

def task_status(platform: Platform, task_id: str) -> str {
    if task_id not in platform.tasks { return "unknown"; }
    return platform.tasks[task_id].status;
}

def audit_event_types(platform: Platform) -> list[str] {
    types: list[str] = [];
    for event in platform.audits {
        types.append(event.event_type);
    }
    return sorted(types);
}

test "diamond revisit is claimed once" {
    p = new_platform();
    assert (register_task(p, "a", "s", "claude-code", 900, False));
    assert (register_task(p, "b", "s", "claude-code", 900, False));
    assert (register_task(p, "c", "s", "claude-code", 900, False));
    assert (register_task(p, "d", "s", "claude-code", 900, False));
    assert (start_task(p, "a", 10));

    assert (link_delegation(p, "a", "c"));
    assert (link_delegation(p, "a", "b"));
    assert (link_delegation(p, "c", "d"));
    assert (link_delegation(p, "b", "d"));
    assert (link_delegation(p, "d", "a"));

    stopped = terminate_task(p, "a", "ops", 40);
    assert (sorted(stopped) == ["b", "c", "d"]);
    assert (task_status(p, "a") == "terminated");
    assert (task_status(p, "d") == "terminated");
    assert (len(audit_event_types(p)) == 5);
}

test "unknown ids and ceiling limits are tolerated" {
    p = new_platform(sync_limit=10, async_limit=20);
    assert (configure_adapter(p, "hermes", 5));
    assert (not configure_adapter(p, "hermes", -1));
    assert (not register_task(p, "too-long", "s", "hermes", 11, False));
    assert (not register_task(p, "async-too-long", "s", "hermes", 21, True));
    assert (register_task(p, "async-ok", "s", "hermes", 20, True));
    assert (register_task(p, "sync-ok", "s", "hermes", 10, False));
    assert (task_status(p, "missing") == "unknown");
    assert (terminate_task(p, "missing", "ops", 1) == []);
    assert (not link_delegation(p, "missing", "sync-ok"));
}

test "task transitions reject invalid repeats" {
    p = new_platform();
    assert (register_task(p, "t", "skill", "crewai", 900, False));
    assert (not register_task(p, "t", "skill", "crewai", 900, False));
    assert (start_task(p, "t", 100));
    assert (not start_task(p, "t", 101));
    assert (finish_task(p, "t", "completed", 120));
    assert (not finish_task(p, "t", "failed", 130));
    assert (task_status(p, "t") == "completed");
    assert (terminate_task(p, "t", "ops", 140) == []);
    assert (audit_event_types(p) == ["task_executed", "task_executed"]);
}
