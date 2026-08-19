walker:priv create_task {
    has title: str;

    can create with Root entry {
        new_task = here ++> Task(title=self.title);
        report new_task;
    }
}
