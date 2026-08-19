# big_component.impl.jac
impl BigComponent.fetchTasks {
    tasks = await get_tasks();
}

impl BigComponent.addTask {
    if newTitle.strip() {
        created = await add_task(newTitle.strip());
        tasks = tasks + [created];
        newTitle = "";
    }
}

# New feature: remove a task both on the server and in local state.
impl BigComponent.deleteTask(id: str) {
    await delete_task(id);
    tasks = [t for t in tasks if jid(t) != id];
}
