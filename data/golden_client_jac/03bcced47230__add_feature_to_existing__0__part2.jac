"""DeleteTask plus a new DeleteCompleted bulk walker."""

node Task {
    has title: str,
        done: bool = False,
        category: str = "other";
}

walker DeleteTask {
    has task_id: str;

    can search with Root entry { visit [-->]; }

    can remove with Task entry {
        if jid(here) == self.task_id {
            del here;
            report {"deleted": self.task_id};
            disengage;
        }
    }
}

# New feature: delete all completed tasks in one pass.
walker DeleteCompleted {
    has removed: int = 0,
        reports: list[dict[str, int]] = [];

    can search with Root entry { visit [-->]; }

    can prune with Task entry {
        if here.done {
            self.removed += 1;
            del here;
        }
    }

    can finish with Root exit { report {"removed": self.removed}; }
}
