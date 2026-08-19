"""Add a task and return it."""
def:pub add_task(title: str) -> Task {
    task = root ++> Task(title=title);
    return task[0];
}
