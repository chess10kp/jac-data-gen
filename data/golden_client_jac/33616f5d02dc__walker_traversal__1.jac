walker ListTasks {
    has reports: list[list[Task]];

    can collect with Root entry {
        report [-->][?:Task];
    }
}

with entry {
    result = root spawn ListTasks();
    tasks: list[Task] = result.reports[0];   # type-safe single-shot collection
}
