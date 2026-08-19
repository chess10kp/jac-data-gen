# big_component.cl.jac
sv import from ..main { Task, get_tasks, add_task, delete_task }

def:pub BigComponent -> JsxElement {
    has tasks: list[Task] = [],
        newTitle: str = "";

    async def fetchTasks;        # signature only
    async def addTask;
    async def deleteTask(id: str);   # new feature: delete a task by id

    return
        <div class="tasks">
            <input
                value={newTitle}
                onChange={lambda e: ChangeEvent { newTitle = e.target.value; }}
            />
            <button onClick={lambda { addTask(); }}>Add</button>
            {[
                <div key={jid(t)} class="task-row">
                    <span>{t.title}</span>
                    <button onClick={lambda { deleteTask(jid(t)); }}>X</button>
                </div> for t in tasks
            ]}
        </div>;
}
