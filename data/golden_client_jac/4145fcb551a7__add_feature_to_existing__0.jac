node Task { has title: str, done: bool = False, category: str = "other", priority: int = 3; }

def:priv set_priority(id: str, priority: int) -> Task | None {
    for task in [root-->][?:Task] {
        if jid(task) == id { task.priority = priority; return task; }
    }
    return None;
}
