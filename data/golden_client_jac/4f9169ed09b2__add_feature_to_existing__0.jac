def:pub delete_task(id: str) -> dict[str, str] {
    for task in [root-->][?:Task] {
        if jid(task) == id { del task; return {"deleted": id}; }
    }
}
