node Task {
    has title: str,
        done: bool = False;
}

# Server: return typed objects directly
def:pub get_tasks -> list[Task] {
    return [root-->][?:Task];
}

def:pub create_task(title: str) -> Task {
    task = root ++> Task(title=title);
    return task[0];
}

# Client: receives hydrated Task instances
cl {
    sv import from .main { get_tasks, create_task }

    def:pub app -> JsxElement {
        has tasks: list = [];

        async can with entry {
            tasks = await get_tasks();  # list of Task objects
        }

        async def addTask(title: str) -> None {
            task = await create_task(title);  # a Task object
            tasks = tasks + [task];
        }

        return <div>
            {[<span key={t.title}>{t.title} - {t.done}</span> for t in tasks]}
        </div>;
    }
}
