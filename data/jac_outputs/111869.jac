"""Checks to see if a task is complete."""
def is_task_complete(
    task: dict[str, str | int],
    task_runs: list[dict[str, str | int]],
    redundancy: int,
    task_id_field: str = 'id',
    task_run_id_field: str = 'task_id',
    error: bool | None = None
) -> bool | None {
    if redundancy <= 0 {
        return error;
    }
    count = 0;
    task_id = task[task_id_field];
    for tr in task_runs {
        tr_id = tr[task_run_id_field];
        if task_id == tr_id {
            count += 1;
            if count >= redundancy {
                return True;
            }
        }
    }
    return False;
}