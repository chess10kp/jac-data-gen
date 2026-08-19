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

"""Delete a task."""
def:pub delete_task(id: str) -> dict[str, str] {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            del task;
            return {"deleted": id};
        }
    }
    return {};
}

cl def:pub app -> JsxElement {
    has tasks: list = [],
        task_text: str = "",
        view: str = "all";

    async can with entry {
        tasks = await get_tasks();
    }

    async def add_new_task {
        if task_text.strip() {
            task = await add_task(task_text.strip());
            tasks = tasks + [task];
            task_text = "";
        }
    }

    async def toggle(id: str) {
        updated = await toggle_task(id);
        tasks = [updated if jid(t) == id else t for t in tasks];
    }

    async def remove(id: str) {
        await delete_task(id);
        tasks = [t for t in tasks if jid(t) != id];
    }

    remaining = len([t for t in tasks if not t.done]);

    return
        <div class="container">
            <h1>Day Planner</h1>
            <div class="input-row">
                <input
                    class="input"
                    value={task_text}
                    onChange={lambda e: ChangeEvent { task_text = e.target.value; }}
                    onKeyPress={lambda e: KeyboardEvent {
                        if e.key == "Enter" { add_new_task(); }
                    }}
                    placeholder="What needs to be done today?"
                />
                <button class="btn-add" onClick={add_new_task}>Add</button>
            </div>
            <div class="filters">
                <button
                    class={"filter " + ("active" if view == "all" else "")}
                    onClick={lambda { view = "all"; }}
                >All</button>
                <button
                    class={"filter " + ("active" if view == "active" else "")}
                    onClick={lambda { view = "active"; }}
                >Active</button>
                <button
                    class={"filter " + ("active" if view == "done" else "")}
                    onClick={lambda { view = "done"; }}
                >Completed</button>
            </div>
            {[
                <div key={jid(t)} class="task-item">
                    <input
                        type="checkbox"
                        checked={t.done}
                        onChange={lambda { toggle(jid(t)); }}
                    />
                    <span class={"task-title " + ("task-done" if t.done else "")}>
                        {t.title}
                    </span>
                    <button
                        class="btn-delete"
                        onClick={lambda { remove(jid(t)); }}
                    >
                        X
                    </button>
                </div>
                for t in tasks
                if view == "all"
                    or (view == "active" and not t.done)
                    or (view == "done" and t.done)
            ]}
            <div class="count">{remaining} {("task" if remaining == 1 else "tasks")} remaining</div>
        </div>;
}
