"""Delete a todo by its jid from the caller's private root.

`del here` detaches every edge incident to the node too -- there is
no need to clean up connections first.
"""

node Todo {
    has title: str;
    has done: bool = False;
}

walker:priv add_todo {
    has title: str;

    can create with Root entry {
        report {"id": jid(here ++> Todo(title=self.title))};
    }
}

walker:priv delete_todo {
    has todo_id: str;

    can find with Root entry {
        visit [-->];
    }

    can remove with Todo entry {
        if jid(here) == self.todo_id {
            del here;  # detaches incident edges automatically
            report {"deleted": self.todo_id};
            disengage;
        }
        visit [-->];
    }
}

walker list_todos {
    can list with Root entry {
        report [t.title for t in [-->][?:Todo]];
    }
}

with entry {
    ids = [];
    for title in ["mow lawn", "call dentist", "renew passport"] {
        r = root spawn add_todo(title=title);
        ids.append(r.reports[0]["id"]);
    }

    before = root spawn list_todos();
    print("before:", before.reports);

    root spawn delete_todo(todo_id=ids[1]);

    after = root spawn list_todos();
    print("after :", after.reports);
}
