"""Team task board capstone: priv CRUD, aggregate stats, access hook.

For my team I want a shared board in Jac. The design: the Board node is
an app-owned commons, so its archetype policy opens every instance at
AccessLevel.CONNECT -- teammates may attach tasks without anyone
remembering a grant. Tasks themselves are user-owned contributions,
armed with READ as they are created. A walker:priv CRUD set manages
each member's own view, and an aggregate stats walker reports board
health in one response at Root exit. Runs standalone via the entry
block; under `jac start` each walker is an authenticated endpoint.
"""

node Board {
    has name: str;

    # Per-archetype invariant: the board itself is open structure.
    def __jac_access__ -> AccessLevel {
        return AccessLevel.CONNECT;
    }
}

node Task {
    has title: str;
    has assignee: str = "";
    has done: bool = False;
}

edge Boards { }   # root --> Board
edge Holds { }    # Board --> Task

walker:priv open_board {
    has name: str;

    can run with Root entry {
        b = here +>: Boards() :+> Board(name=self.name);
        report {"board": jid(b), "name": b.name};
    }
}

# ------------------------------------------------------------- CRUD set

walker:priv create_task {
    has title: str;
    has assignee: str = "";

    can find with Root entry {
        visit [->:Boards:->];  # land on my boards
    }

    can add with Board entry {
        t = here +>: Holds() :+> Task(title=self.title, assignee=self.assignee);
        grant(t, level=AccessLevel.READ);  # teammates can see the task
        report {"created": jid(t), "title": t.title};
    }
}

walker:priv complete_task {
    has task_id: str;

    can find with Root entry {
        visit [->:Boards:-> ->:Holds:->];  # two hops to every task
    }

    can finish with Task entry {
        if jid(here) == self.task_id {
            here.done = True;
            report {"done": here.title};
            disengage;
        }
    }
}

walker:priv delete_task {
    has task_id: str;

    can find with Root entry {
        visit [->:Boards:-> ->:Holds:->];
    }

    can remove with Task entry {
        if jid(here) == self.task_id {
            del here;  # detaches its Holds edge automatically
            report {"deleted": self.task_id};
            disengage;
        }
    }
}

# -------------------------------------------------------- aggregate stats

walker:priv board_stats {
    has total: int = 0;
    has completed: int = 0;
    has by_assignee: dict[str, int] = {};

    can start with Root entry {
        visit [->:Boards:->];
    }

    can hop with Board entry {
        visit [->:Holds:->];
    }

    can tally with Task entry {
        self.total += 1;
        if here.done {
            self.completed += 1;
        }
        who = here.assignee or "unassigned";
        if who not in self.by_assignee {
            self.by_assignee[who] = 0;
        }
        self.by_assignee[who] += 1;
    }

    can summarize with Root exit {
        report {
            "total": self.total,
            "completed": self.completed,
            "open": self.total - self.completed,
            "completion_rate": (self.completed / self.total * 100) if self.total > 0 else 0.0,
            "by_assignee": self.by_assignee,
        };
    }
}

with entry {
    b = root spawn open_board(name="sprint 42");
    print("board:", b.reports);

    ids = [];
    for spec in [("wire auth", "kim"), ("seed data", "kim"), ("draft changelog", ""), ("load test", "raj")] {
        r = root spawn create_task(title=spec[0], assignee=spec[1]);
        ids.append(r.reports[0]["created"]);
    }

    root spawn complete_task(task_id=ids[0]);
    root spawn complete_task(task_id=ids[1]);
    root spawn delete_task(task_id=ids[3]);

    stats = root spawn board_stats();
    print("stats:", stats.reports);
}
