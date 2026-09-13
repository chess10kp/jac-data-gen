node Intent {
    has key: str;
}

node Worker {
    has name: str;
}

edge Next {}
edge Binds {}

obj Registry {
    has intents: dict[str, Intent] = {};
    has workers: dict[str, Worker] = {};
}

walker Reach {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can scan with Intent entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        print(here.key);
        if here.key == self.target {
            self.found = True;
        } else {
            for child in [here ->:Next:->][?:Intent] {
                visit :0: [child];
            }
        }
    }
}

walker Authorize {
    has worker_name: str;
    has claimed: dict[str, bool] = {};
    has allowed: bool = False;

    can inspect with Intent entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        print(here.key);
        for worker_node in [here ->:Binds:->][?:Worker] {
            if worker_node.name == self.worker_name {
                self.allowed = True;
            }
        }
    }
}

def new_registry() -> Registry {
    return Registry();
}

def register_worker(registry: Registry, worker_name: str) -> bool {
    if worker_name in registry.workers {
        return False;
    }
    worker_node = Worker(name=worker_name);
    registry.workers[worker_name] = worker_node;
    return True;
}

def create_intent(registry: Registry, intent_id: str) -> bool {
    if intent_id in registry.intents {
        return False;
    }
    intent_node = Intent(key=intent_id);
    registry.intents[intent_id] = intent_node;
    return True;
}

def expose_worker(
    registry: Registry, intent_id: str, worker_name: str
) -> bool {
    if intent_id not in registry.intents {
        return False;
    }
    if worker_name not in registry.workers {
        return False;
    }
    intent_node = registry.intents[intent_id] as Intent;
    worker_node = registry.workers[worker_name] as Worker;
    check = intent_node spawn Authorize(
        worker_name=worker_name, claimed={}
    );
    if check.allowed {
        return False;
    }
    intent_node +>:Binds:+> worker_node;
    return True;
}

def add_dependency(
    registry: Registry, parent_id: str, child_id: str
) -> bool {
    if parent_id not in registry.intents {
        return False;
    }
    if child_id not in registry.intents {
        return False;
    }
    parent_node = registry.intents[parent_id] as Intent;
    child_node = registry.intents[child_id] as Intent;
    parent_node +>:Next:+> child_node;
    return True;
}

def can_queue(
    registry: Registry, intent_id: str, worker_name: str
) -> bool {
    if intent_id not in registry.intents {
        return False;
    }
    if worker_name not in registry.workers {
        return False;
    }
    intent_node = registry.intents[intent_id] as Intent;
    w = intent_node spawn Authorize(
        worker_name=worker_name, claimed={}
    );
    return w.allowed;
}

def is_reachable(
    registry: Registry, start_id: str, target_id: str
) -> bool {
    if start_id not in registry.intents {
        return False;
    }
    if target_id not in registry.intents {
        return False;
    }
    start_node = registry.intents[start_id] as Intent;
    w = start_node spawn Reach(target=target_id, claimed={});
    return w.found;
}
