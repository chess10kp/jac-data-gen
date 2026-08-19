"""ListTasks walker with optional category filtering."""

node Task {
    has title: str,
        done: bool = False,
        category: str = "other";
}

walker ListTasks {
    has category: str = "",
        results: list[Task] = [],
        reports: list[list[Task]] = [];

    can start with Root entry {
        visit [-->];
    }

    can collect with Task entry {
        if self.category == "" or here.category == self.category {
            self.results.append(here);
        }
    }

    can done with Root exit {
        report self.results;
    }
}
