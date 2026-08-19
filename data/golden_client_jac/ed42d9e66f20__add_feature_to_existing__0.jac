def:priv get_tasks(only_active: bool) -> list[Task] {
    tasks = [root-->][?:Task];
    return [t for t in tasks if not t.done] if only_active else tasks;
}
