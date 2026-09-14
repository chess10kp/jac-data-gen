# PROGRAM: dachent/model_proctor#35

edge NextEvent {}
edge NextWake {}
edge Child {}
edge Depends {}

node Event {
    has event_id: str;
    has kind: str;
    has next_event: Event | None = None;
}

node Wake {
    has wake_id: str;
    has reason: str;
    has next_wake: Wake | None = None;
}

node Task {
    has task_id: str;
    has first_event: Event | None = None;
    has last_event: Event | None = None;
    has first_wake: Wake | None = None;
    has last_wake: Wake | None = None;
    has projected: str = "pending";
}

node Feature {
    has feature_id: str;
    has risk: int = 0;
}

walker Replay {
    has claimed: dict[str, bool] = {};
    has status: str = "pending";

    can start with Task entry {
        if "task:" + here.task_id in self.claimed { skip; }
        self.claimed["task:" + here.task_id] = True;
        event = here.first_event;
        if event != None {
            visit :0: [event];
        }
        print("replay " + here.task_id);
    }

    can event with Event entry {
        if "event:" + here.event_id in self.claimed { skip; }
        self.claimed["event:" + here.event_id] = True;
        if here.kind == "started" {
            self.status = "running";
        } elif here.kind == "accepted" {
            self.status = "accepted";
        } elif here.kind == "failed" {
            self.status = "failed";
        } elif here.kind == "waiting" {
            self.status = "waiting";
        }
        next_event = here.next_event;
        if next_event != None {
            visit :0: [next_event];
        }
        print("event " + here.event_id);
    }
}

walker WakeScan {
    has claimed: dict[str, bool] = {};
    has reasons: list[str] = [];

    can start with Task entry {
        if "task:" + here.task_id in self.claimed { skip; }
        self.claimed["task:" + here.task_id] = True;
        wake = here.first_wake;
        if wake != None {
            visit :0: [wake];
        }
        print("wake scan " + here.task_id);
    }

    can wake with Wake entry {
        if "wake:" + here.wake_id in self.claimed { skip; }
        self.claimed["wake:" + here.wake_id] = True;
        self.reasons.append(here.reason);
        next_wake = here.next_wake;
        if next_wake != None {
            visit :0: [next_wake];
        }
        print("wake " + here.wake_id);
    }
}

walker TaskLookup {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: Task | None = None;

    can task_step with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        if here.task_id == self.wanted {
            self.found = here;
        }
        for child in [here ->:Child:->][?:Task] {
            visit :0: [child];
        }
        print("task " + here.task_id);
    }
}

walker FeatureClosure {
    has claimed: dict[str, bool> = {};
    has names: list[str] = [];

    can feature_step with Feature entry {
        if here.feature_id in self.claimed { skip; }
        self.claimed[here.feature_id] = True;
        self.names.append(here.feature_id);
        for dep in [here ->:Depends:->][?:Feature] {
            visit :0: [dep];
        }
        print("feature " + here.feature_id);
    }
}

def record_event(task: Task, event_id: str, kind: str) -> None {
    event = Event(event_id=event_id, kind=kind);
    first = task.first_event;
    if first == None {
        task.first_event = event;
    } else {
        last = task.last_event;
        if last != None {
            last +>:NextEvent:+> event;
        }
    }
    task.last_event = event;
}

def replay_status(task: Task) -> str {
    w = task spawn Replay(claimed={});
    task.projected = w.status;
    return task.projected;
}

def enqueue_wake(task: Task, wake_id: str, reason: str) -> None {
    wake = Wake(wake_id=wake_id, reason=reason);
    first = task.first_wake;
    if first == None {
        task.first_wake = wake;
    } else {
        last = task.last_wake;
        if last != None {
            last +>:NextWake:+> wake;
        }
    }
    task.last_wake = wake;
}

def durable_wakes(task: Task) -> list[str] {
    w = task spawn WakeScan(claimed={});
    return w.reasons;
}

def task_state(root_node: Task, wanted: str) -> str {
    w = root_node spawn TaskLookup(wanted=wanted, claimed={});
    candidate = w.found;
    if candidate == None {
        return "unknown";
    }
    return replay_status(candidate);
}

def verification_features(graph_root: Feature) -> list[str] {
    w = graph_root spawn FeatureClosure(claimed={});
    return sorted(w.names);
}

def risk_blast_radius(graph_root: Feature, threshold: int) -> list[str] {
    if graph_root.risk < threshold {
        return [];
    }
    return verification_features(graph_root);
}
