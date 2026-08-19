node Task { has title: str, done: bool = False; }

walker:pub create_todo {
    has text: str;
    can create with `root entry {
        new_todo = here ++> Task(title=self.text);
        report new_todo[0];  # the created Task, not a 1-element list
    }
}
