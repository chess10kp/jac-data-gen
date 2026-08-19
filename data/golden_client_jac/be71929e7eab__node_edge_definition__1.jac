walker ToggleTask {
    has task_id: str,
        reports: list[Task] = [];

    can search with Root entry { visit [-->]; }

    can toggle with Task entry {
        if jid(here) == self.task_id {
            here.done = not here.done;
            report here;
            disengage;  # Found it -- stop visiting remaining nodes
        }
    }
}
