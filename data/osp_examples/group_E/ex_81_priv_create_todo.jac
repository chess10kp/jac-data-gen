"""Create todos under the caller's root with a private walker.

walker:priv drops the walker on the authenticated user's private root
automatically. The entry block seeds data so the file also runs
standalone.

Server usage:
    jac start ex_81_priv_create_todo.jac
    curl -X POST http://localhost:8000/walker/create_todo \
         -H "Content-Type: application/json" -d '{"title": "Buy milk"}'
"""

node Todo {
    has title: str;
    has done: bool = False;
}

# :priv makes this an authenticated endpoint pinned to the caller's root.
walker:priv create_todo {
    has title: str;

    can create with Root entry {
        # `++>` mirrors its right-hand side, so this is the created node.
        new_todo = here ++> Todo(title=self.title);
        report {"id": jid(new_todo), "title": new_todo.title};
    }
}

walker list_todos {
    can list with Root entry {
        for t in [-->][?:Todo] {
            report {"title": t.title, "done": t.done};
        }
    }
}

with entry {
    root spawn create_todo(title="buy oat milk");
    root spawn create_todo(title="ship the release");
    root spawn list_todos();
}
