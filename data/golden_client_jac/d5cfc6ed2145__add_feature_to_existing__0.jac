def:pub add_task(title: str) -> dict { return {"title": title, "done": False}; }
def:priv get_tasks -> list { return []; }
def:protect helper -> None { }
def:pub complete_task(task_id: int) -> dict { return {"id": task_id, "done": True}; }
