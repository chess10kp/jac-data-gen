cl import "./styles.css";

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

cl def:pub app -> JsxElement {
    has tasks: list = [],
        task_text: str = "",
        show_done: bool = True;

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

    return
        <div class="container">
            <h1>Day Planner</h1>
            <div class="input-row">
                <input
                    class="input"
                    value={task_text}
                    onChange={lambda e: ChangeEvent { task_text = e.target.value; }}
                    placeholder="What needs to be done today?"
                />
                <button class="btn-add" onClick={add_new_task}>Add</button>
            </div>
            <label class="filter-toggle">
                <input
                    type="checkbox"
                    checked={show_done}
                    onChange={lambda { show_done = not show_done; }}
                />
                Show completed
            </label>
            {[
                <div key={jid(t)} class="task-item">
                    <span class="task-title">{t.title}</span>
                </div> for t in tasks if show_done or not t.done
            ]}
        </div>;
}
