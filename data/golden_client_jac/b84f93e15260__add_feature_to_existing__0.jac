def:pub add_task(title: str, priority: int = 1) -> Task {
    task = root ++> Task(title=title);
    return task[0];
}
