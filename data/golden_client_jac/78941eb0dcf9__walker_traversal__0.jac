node Task {
    has title: str;
    has done: bool = False;
}

walker:priv ToggleTask {
    has task_id: str,
        reports: list[Task] = [];   # typed report channel

    can search with Root entry {
        visit [-->];
    }

    can toggle with Task entry {
        if jid(here) == self.task_id {
            here.done = not here.done;
            report here;        # `here` is Task -- type-checked against list[Task]
            disengage;
        }
    }
}

with entry {
    result = root spawn ToggleTask(task_id="abc123");
    toggled: Task = result.reports[0];     # hydrated as Task on the consumer side
}
