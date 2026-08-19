walker:priv SetPriority {
        has task_id: str,
            priority: int,
            reports: list[Task] = [];

        can apply with Root entry {
            if jid(here) == self.task_id {
                here.priority = self.priority;
                report here;
            }
        }
    }
