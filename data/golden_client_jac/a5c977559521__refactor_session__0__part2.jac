"""Body for TaskItem."""

impl TaskItem -> JsxElement {
    return
        <div class="task-item">
            <input type="checkbox" checked={task.done} onChange={onToggle}/>
            <span class={"task-title " + ("task-done" if task.done else "")}>
                {task.title}
            </span>
            <button class="btn-delete" onClick={onDelete}>X</button>
        </div>;
}
