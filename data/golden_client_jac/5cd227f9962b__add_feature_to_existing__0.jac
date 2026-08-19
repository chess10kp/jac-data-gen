impl BigComponent.deleteTask(id: str) {
    await delete_task(id);
    tasks = [t for t in tasks if jid(t) != id];
}
