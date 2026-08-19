sv import from ...main { get_tasks }

cl {
    def:pub TaskList() -> JsxElement {
        has tasks: list = [];

        async can with entry {
            result = root() spawn get_tasks();
            if result.reports and result.reports.length > 0 {
                tasks = result.reports[0];
            }
        }

        return <ul>
            {[<li key={task.id}>{task.title}</li> for task in tasks]}
        </ul>;
    }
}
