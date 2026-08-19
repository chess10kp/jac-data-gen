"""Task read endpoint with an optional done-status filter."""

node Task {
    has title: str,
        done: bool = False,
        category: str = "other";
}

# New feature: `only_active=True` returns just the unfinished tasks.
def:priv get_tasks(only_active: bool = False) -> list[Task] {
    tasks = [root-->][?:Task];
    if only_active {
        return [t for t in tasks if not t.done];
    }
    return tasks;
}
