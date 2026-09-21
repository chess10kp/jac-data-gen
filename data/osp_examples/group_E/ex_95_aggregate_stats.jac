"""Aggregate stats over a private todo graph into one report.

Counters accumulate during the walk and a single dict is reported at
Root exit; division by zero is guarded for accounts with no todos.
"""

node Todo {
    has title: str;
    has done: bool = False;
    has points: int = 1;
}

walker:priv add_todo {
    has title: str;
    has done: bool = False;

    can run with Root entry {
        here ++> Todo(title=self.title, done=self.done);
    }
}

walker:priv get_stats {
    has total: int = 0;
    has completed: int = 0;
    has effort_done: int = 0;
    has effort_total: int = 0;

    can count with Root entry {
        visit [-->];
    }

    can tally with Todo entry {
        self.total += 1;
        self.effort_total += here.points;
        if here.done {
            self.completed += 1;
            self.effort_done += here.points;
        }
    }

    can summarize with Root exit {
        report {
            "total": self.total,
            "completed": self.completed,
            "pending": self.total - self.completed,
            "completion_rate": (self.completed / self.total * 100) if self.total > 0 else 0.0,
            "points_burned": self.effort_done,
            "points_total": self.effort_total,
        };
    }
}

with entry {
    root spawn add_todo(title="set up CI", done=True);
    root spawn add_todo(title="write API docs", done=True);
    root spawn add_todo(title="onboard beta users");
    root spawn add_todo(title="price the tiers");

    stats = root spawn get_stats();
    print(stats.reports);
}
