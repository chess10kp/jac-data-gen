"""Single task row -- presentational."""

sv import from ..main { Task }

def:pub TaskItem(task: Task) -> JsxElement {
    return
        <div class="task-item">
            <input type="checkbox" checked={task.done}/>
            <span class={"task-title " + ("task-done" if task.done else "")}>
                {task.title}
            </span>
        </div>;
}
