# main.jac - Combined backend and frontend

# === Backend: Data Model ===
node Task {
    has title: str;
    has completed: bool = False;
}

# === Backend: Walkers ===
walker:pub get_tasks {
    can fetch with Root entry {
        report [-->][?:Task];
    }
}

walker:pub add_task {
    has title: str;

    can create with Root entry {
        task = Task(title=self.title);
        root ++> task;
        report task;
    }
}

walker:pub toggle_task {
    has task_id: str;

    can toggle with Root entry {
        for t in [-->][?:Task] {
            if jid(t) == self.task_id {
                t.completed = not t.completed;
                report t;
                return;
            }
        }
    }
}

# === Frontend: UI ===
cl {
    def:pub app() -> JsxElement {
        has tasks: list = [];
        has input_text: str = "";
        has loading: bool = True;

        # Load tasks on mount
        async can with entry {
            result = root spawn get_tasks();
            if result.reports {
                tasks = result.reports;
            }
            loading = False;
        }

        async def add() -> None {
            if input_text.trim() {
                result = root spawn add_task(title=input_text.trim());
                if result.reports and result.reports.length > 0 {
                    tasks = tasks + [result.reports[0]];
                }
                input_text = "";
            }
        }

        async def toggle(task_id: str) -> None {
            result = root spawn toggle_task(task_id=task_id);
            if result.reports and result.reports.length > 0 {
                updated = result.reports[0];
                tasks = [updated if jid(t) == task_id else t for t in tasks];
            }
        }

        return <div className="app">
            <h1>My Tasks</h1>

            <div className="input-row">
                <input
                    value={input_text}
                    onChange={lambda e: ChangeEvent { input_text = e.target.value; }}
                    onKeyDown={lambda e: KeyboardEvent {
                        if e.key == "Enter" { add(); }
                    }}
                    placeholder="Add a task..."
                />
                <button onClick={lambda -> None { add(); }}>Add</button>
            </div>

            {loading and <p>Loading...</p>}

            {not loading and (
                <ul>
                    {[
                        <li
                            key={jid(t)}
                            style={{"textDecoration": t.completed and "line-through"}}
                            onClick={lambda -> None { toggle(jid(t)); }}
                        >
                            {t.title}
                        </li>
                        for t in tasks
                    ]}
                </ul>
            )}
        </div>;
    }
}
