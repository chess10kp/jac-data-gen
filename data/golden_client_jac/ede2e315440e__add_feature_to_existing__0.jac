walker AddTask {
    has title: str, due_date: str;
    can create with Root entry {
        new_task = here ++> Task(title=self.title, due_date=self.due_date, ...);
    }
}
