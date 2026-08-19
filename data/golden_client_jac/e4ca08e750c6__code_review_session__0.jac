sv import from ...main { add_task, toggle_task, delete_task }

cl {
    def:pub TaskManager() -> JsxElement {
        has tasks: list = [];

        async def handle_add(title: str) -> None {
            result: any = root spawn add_task(title=title);
            if result.reports and result.reports.length > 0 {
                tasks = tasks + [result.reports[0]];
            }
        }

        async def handle_toggle(task_id: str) -> None {
            result: any = root spawn toggle_task(task_id=task_id);
            if result.reports and result.reports.length > 0 {
                updated = result.reports[0];
                tasks = [updated if t["id"] == task_id else t for t in tasks];
            }
        }

        async def handle_delete(task_id: str) -> None {
            result: any = root spawn delete_task(task_id=task_id);
            if result.reports and result.reports[0]["success"] {
                tasks = [t for t in tasks if t["id"] != task_id];
            }
        }

        return <div>...</div>;
    }
}
