node Task {
    has title: str,
        done: bool = False,
        priority: int = 1;
}

"""Add a task with an optional priority and return it."""
def:pub add_task(title: str, priority: int = 1) -> Task {
    task = root ++> Task(title=title, priority=priority);
    return task[0];
}
