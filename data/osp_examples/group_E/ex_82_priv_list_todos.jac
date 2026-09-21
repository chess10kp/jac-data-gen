"""List all todos on the caller's root as one JSON array.

Collect during traversal and send everything back in a single report;
walker:priv scopes the listing to the authenticated user's own graph.
"""

node Todo {
    has title: str;
    has done: bool = False;
    has priority: int = 0;
}

walker:priv add_todo {
    has title: str;
    has priority: int = 0;

    can create with Root entry {
        here ++> Todo(title=self.title, priority=self.priority);
    }
}

# Read side of the CRUD pair: gather, then report a single summary.
walker:priv list_todos {
    has items: list[dict] = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with Todo entry {
        self.items.append({
            "id": jid(here),
            "title": here.title,
            "done": here.done,
            "priority": here.priority,
        });
    }

    can finish with Root exit {
        report {"count": len(self.items), "todos": self.items};
    }
}

with entry {
    root spawn add_todo(title="write docs", priority=2);
    root spawn add_todo(title="fix login bug", priority=1);
    root spawn add_todo(title="water plants", priority=3);
    result = root spawn list_todos();
    print(result.reports);
}
