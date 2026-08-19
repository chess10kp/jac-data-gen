sv import from ...main { get_tasks, add_task, toggle_task, delete_task }

cl {
    def:pub TaskManager() -> JsxElement {
        has tasks: list = [];
        has new_title: str = "";
        has loading: bool = True;

        # Load tasks on mount
        async can with entry {
            await load_tasks();
        }

        async def load_tasks() -> None {
            loading = True;
            result = root spawn get_tasks();
            if result.reports and result.reports.length > 0 {
                tasks = result.reports[0];
            }
            loading = False;
        }

        # Add new task
        async def handle_add() -> None {
            if new_title.trim() {
                try {
                    result = root spawn add_task(title=new_title.trim());
                    if result.reports and result.reports.length > 0 {
                        tasks = tasks + [result.reports[0]];
                        new_title = "";
                    }
                } except Exception as e {
                    print(f"Add failed: {e}");
                }
            }
        }

        # Toggle task completion
        async def handle_toggle(task_id: str) -> None {
            result = root spawn toggle_task(task_id=task_id);
            if result.reports and result.reports.length > 0 {
                updated = result.reports[0];
                tasks = [updated if jid(t) == task_id else t for t in tasks];
            }
        }

        # Delete task
        async def handle_delete(task_id: str) -> None {
            result = root spawn delete_task(task_id=task_id);
            if result.reports and result.reports.length > 0 {
                tasks = [t for t in tasks if jid(t) != task_id];
            }
        }

        return <div>
            <div className="add-task">
                <input
                    value={new_title}
                    onChange={lambda e: ChangeEvent { new_title = e.target.value; }}
                    onKeyDown={lambda e: KeyboardEvent {
                        if e.key == "Enter" { handle_add(); }
                    }}
                    placeholder="New task..."
                />
                <button onClick={lambda -> None { handle_add(); }}>
                    Add
                </button>
            </div>

            {loading and <p>Loading...</p>}

            <ul className="task-list">
                {[
                    <li key={jid(task)}>
                        <input
                            type="checkbox"
                            checked={task.completed}
                            onChange={lambda -> None { handle_toggle(jid(task)); }}
                        />
                        <span className={task.completed and "completed"}>
                            {task.title}
                        </span>
                        <button onClick={lambda -> None { handle_delete(jid(task)); }}>
                            Delete
                        </button>
                    </li>
                    for task in tasks
                ]}
            </ul>
        </div>;
    }
}
