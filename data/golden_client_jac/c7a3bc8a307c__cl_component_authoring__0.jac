# Import walkers from your main module
sv import from ...main { get_tasks, add_task, toggle_task }

cl {
    def:pub TaskList() -> JsxElement {
        has tasks: list = [];
        has loading: bool = True;
        has error: str = "";

        # Fetch data on component mount
        async can with entry {
            await load_tasks();
        }

        async def load_tasks() -> None {
            loading = True;
            error = "";
            try {
                result = root spawn get_tasks();
                if result.reports and result.reports.length > 0 {
                    tasks = result.reports[0];
                }
            } except Exception as e {
                error = f"Failed to load: {e}";
            }
            loading = False;
        }

        if loading {
            return <p>Loading tasks...</p>;
        }

        if error {
            return <p className="error">Error: {error}</p>;
        }

        return <ul>
            {[<li key={jid(task)}>{task.title}</li> for task in tasks]}
        </ul>;
    }
}
