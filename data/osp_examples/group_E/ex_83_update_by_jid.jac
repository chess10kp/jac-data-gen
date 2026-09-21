"""Update a todo by its jid, found by traversal rather than a query.

The walker walks the caller's graph until jid(here) matches, mutates
the node in place, and stops early with disengage.
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

walker:priv update_todo {
    has todo_id: str;
    has new_title: str = "";
    has new_done: bool | None = None;

    can find with Root entry {
        visit [-->];
    }

    can update with Todo entry {
        if jid(here) == self.todo_id {
            if self.new_title != "" {
                here.title = self.new_title;
            }
            if self.new_done is not None {
                here.done = self.new_done;
            }
            # Report becomes the HTTP response; it also prints to stdout.
            report {"updated": self.todo_id, "title": here.title, "done": here.done};
            disengage;  # matched and mutated -- no need to walk further
        }
        visit [-->];
    }
}

with entry {
    # A spawn whose target id never matches simply produces no report.
    created = root spawn add_todo(title="draft blog post");
    todo_id = created.reports[0]["id"];

    root spawn update_todo(todo_id=todo_id, new_title="publish blog post", new_done=True);

    # A second spawn against a bogus id simply reports nothing.
    root spawn update_todo(todo_id="n0suchid", new_title="ghost");
}
