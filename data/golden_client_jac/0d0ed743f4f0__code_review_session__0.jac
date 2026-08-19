node Todo {
    has title: str;
    has done: bool = False;
}

walker add_todo {
    has title: str;

    can create with Root entry {
        # `++>` returns a LIST of connected nodes, so index [0] for the single Todo
        new_todo = (here ++> Todo(title=self.title))[0];
        report new_todo;
    }
}

walker list_todos {
    can list with Root entry {
        for todo in [-->][?:Todo] {
            report todo;
        }
    }
}
