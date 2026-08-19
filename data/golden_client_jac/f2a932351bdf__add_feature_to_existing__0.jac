def:priv add_task(title: str, priority: int) -> Task {
    category = str(categorize(title)).split(".")[-1].lower();
    task = root ++> Task(title=title, category=category, priority=priority);
    return task[0];
}
