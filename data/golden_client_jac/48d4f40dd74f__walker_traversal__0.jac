sv import from ...main { add_task }

cl {
    async def handle_add() -> None {
        result = root() spawn add_task(title="New task");
        if result.reports and result.reports.length > 0 {
            new_task = result.reports[0];
            tasks = tasks + [new_task];
        }
    }
}
