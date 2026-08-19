"""ToggleTask plus a new SetAllDone bulk walker."""

node Task {
    has title: str,
        done: bool = False,
        category: str = "other";
}

walker ToggleTask {
    has task_id: str,
        reports: list[Task] = [];

    can search with Root entry { visit [-->]; }

    can toggle with Task entry {
        if jid(here) == self.task_id {
            here.done = not here.done;
            report here;
            disengage;
        }
    }
}

# New feature: mark every task done (or not) in a single traversal.
walker SetAllDone {
    has value: bool = True,
        count: int = 0,
        reports: list[int] = [];

    can search with Root entry { visit [-->]; }

    can apply with Task entry {
        here.done = self.value;
        self.count += 1;
    }

    can finish with Root exit { report self.count; }
}
