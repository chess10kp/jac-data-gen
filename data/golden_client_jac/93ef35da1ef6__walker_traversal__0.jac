walker:pub create_todo {
    has text: str;

    can create with Root entry {
        new_todo = here ++> Task(title=self.text);
        report new_todo;  # Client receives a typed Task, not a raw dict
    }
}
