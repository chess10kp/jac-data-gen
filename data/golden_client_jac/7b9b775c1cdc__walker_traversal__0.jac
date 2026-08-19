# Bad: Manual dict return
def:pub get_task(id: str) -> dict {
    task = find_task(id);
    return {"id": jid(task), "title": task.title, "done": task.done};
}

# Good: Typed return -- client receives a hydrated Task instance
def:pub get_task(id: str) -> Task {
    return find_task(id);
}
