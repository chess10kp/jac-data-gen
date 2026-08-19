"""Single task row -- presentational; toggle and delete are passed in."""

sv import from ..main { Task }

def:pub TaskItem(
    task: Task, onToggle: Callable[[], None], onDelete: Callable[[], None]
) -> JsxElement {
    return
        <div class="task-item">
            <input type="checkbox" checked={task.done} onChange={onToggle}/>
            <span class={"task-title " + ("task-done" if task.done else "")}>
                {task.title}
            </span>
            {(<span class={"priority priority-" + str(task.priority)}>
                {("High" if task.priority <= 2 else ("Low" if task.priority >= 4 else "Med"))}
            </span>) if task.priority != 3 else None}
            {(<span class="category">{task.category}</span>)
                if task.category and task.category != "other"
                else None}
            <button class="btn-delete" onClick={onDelete}>X</button>
        </div>;
}
