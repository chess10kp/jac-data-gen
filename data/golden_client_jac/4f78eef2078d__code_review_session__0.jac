# main.jac
node Task {
    has title: str;
    has done: bool = False;
}

walker:pub get_tasks {
    can fetch with Root entry {
        tasks = [-->][?:Task];
        report [{"id": jid(t), "title": t.title, "done": t.done} for t in tasks];
    }
}

walker:pub add_task {
    has title: str;

    can create with Root entry {
        if not self.title.strip() {
            report {"error": "title is required"};
            disengage;
        }
        task = Task(title=self.title);
        root ++> task;
        report {"id": jid(task), "title": task.title, "done": task.done};
    }
}
