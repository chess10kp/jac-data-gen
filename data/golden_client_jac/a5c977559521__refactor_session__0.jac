"""Single task row -- presentational; toggle and delete are passed in."""

sv import from ..main { Task }

def:pub TaskItem(
    task: Task, onToggle: Callable[[], None], onDelete: Callable[[], None]
) -> JsxElement;
