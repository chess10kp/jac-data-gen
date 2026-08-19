# main.jac
node Todo {
    has title: str;
    has done: bool = False;
}

walker:pub add_todo {
    has title: str;

    can create with Root entry {
        todo = here ++> Todo(title=self.title);
        report {"title": todo[0].title, "done": todo[0].done};
    }
}

walker:pub list_todos {
    can fetch with Root entry {
        todos = [-->][?:Todo];
        report [{"title": t.title, "done": t.done} for t in todos];
    }
}

walker:pub health {
    can check with Root entry {
        report {"status": "healthy"};
    }
}
