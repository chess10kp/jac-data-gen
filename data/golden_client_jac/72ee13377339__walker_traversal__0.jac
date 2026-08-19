walker:pub create_task {
    has title: str;  # Automatically populated from request body

    can create with Root entry {
        new_task = here ++> Task(title=self.title);
        report new_task;  # Automatically becomes response body
    }
}
