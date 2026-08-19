node Task {
    has title: str,
        done: bool = False;
}

"""Add a task and return it."""
def:pub add_task(title: str) -> Task {
    task = root ++> Task(title=title);
    return task[0];
}

"""Get all tasks."""
def:pub get_tasks -> list[Task] {
    return [root-->][?:Task];
}

"""Toggle a task's done status."""
def:pub toggle_task(id: str) -> Task | None {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            task.done = not task.done;
            return task;
        }
    }
    return None;
}

"""Delete a task by id."""
def:pub delete_task(id: str) -> dict[str, str] {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            del task;
            return {"deleted": id};
        }
    }
    return {};
}

"""Count how many tasks are still pending."""
def:pub count_pending -> int {
    return len([root-->][?:Task, done == False]);
}
