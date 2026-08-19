# Import walkers from backend
sv import from ...main { get_tasks, create_task }

cl {
    def:pub TaskList() -> JsxElement {
        has tasks: list = [];
        has loading: bool = True;

        # Fetch data on component mount
        async can with entry {
            result = root spawn get_tasks();
            if result.reports and result.reports.length > 0 {
                tasks = result.reports[0];
            }
            loading = False;
        }

        if loading {
            return <p>Loading...</p>;
        }

        return <ul>
            {[<li key={task["id"]}>{task["title"]}</li> for task in tasks]}
        </ul>;
    }
}
