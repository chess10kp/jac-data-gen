cl def:pub app -> JsxElement {
    has tasks: list = [],
        task_text: str = "",
        error: str = "";

    async def add_new_task {
        text = task_text.strip();
        if not text {
            error = "Task cannot be empty";
            return;
        }
        if len(text) > 100 {
            error = "Task is too long (max 100 characters)";
            return;
        }
        if text.lower() in [t.title.lower() for t in tasks] {
            error = "That task already exists";
            return;
        }
        task = await add_task(text);
        tasks = tasks + [task];
        task_text = "";
        error = "";
    }

    return
        <div class="container">
            <div class="input-row">
                <input
                    class="input"
                    value={task_text}
                    onChange={lambda e: ChangeEvent { task_text = e.target.value; }}
                    placeholder="What needs to be done today?"
                />
                <button class="btn-add" onClick={add_new_task}>Add</button>
            </div>
            {(<p class="error">{error}</p>) if error else None}
            {[<div key={jid(t)} class="task-item">{t.title}</div> for t in tasks]}
        </div>;
}
