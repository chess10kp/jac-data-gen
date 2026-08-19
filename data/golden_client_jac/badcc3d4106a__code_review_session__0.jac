import from uuid { uuid4 }

node Task {
    has title: str,
        done: bool = False,
        id: str = "";
}

def:pub get_tasks -> list[Task] {
    return [root-->][?:Task];
}

def:pub create_task(title: str) -> Task {
    task = root ++> Task(title=title, id=str(uuid4()));
    return task[0];
}

cl {
    def:pub app -> JsxElement {
        has tasks: list = [];
        async can with entry { tasks = await get_tasks(); }
        return <div>
            {[<span key={t.id}>{t.title}</span> for t in tasks]}
        </div>;
    }
}
