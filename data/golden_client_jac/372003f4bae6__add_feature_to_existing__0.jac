async def add_new_task {
    if not task_text.strip() { return; }
    task = await add_task(task_text.strip());
    tasks = tasks + [task];
    task_text = "";
}
