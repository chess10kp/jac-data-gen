sv import from ...main { get_tasks, create_task }

cl {
    def:pub TaskList() -> JsxElement {
        has tasks: list = [];
        has loading: bool = True;
        has error: str = "";

        async can with entry {
            try {
                result: any = root spawn get_tasks();
                if result.reports and result.reports.length > 0 {
                    tasks = list(result.reports[0]);
                }
            } except Exception as e {
                error = f"Failed to load tasks: {e}";
            }
            loading = False;
        }

        if loading { return <p>Loading...</p>; }
        if error { return <p className="error">{error}</p>; }

        return <ul>
            {[<li key={task["id"]}>{task["title"]}</li> for task in tasks]}
        </ul>;
    }
}
