walker ListTasks {
    has results: list[Task] = [],
        reports: list[list[Task]] = [];

    can start with Root entry {
        visit [-->];
    }

    can collect with Task entry {
        self.results.append(here);
    }

    can done with Root exit {
        report self.results;
    }
}
