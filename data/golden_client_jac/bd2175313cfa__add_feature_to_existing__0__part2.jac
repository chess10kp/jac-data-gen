"""Task node gains a priority field surfaced through its walker ability."""

node Task {
    has title: str,
        done: bool = False,
        category: str = "other",
        priority: int = 3;

    can respond with ListTasks entry {
        if visitor.min_priority == 0 or self.priority <= visitor.min_priority {
            visitor.results.append(self);
        }
    }
}

walker ListTasks {
    has min_priority: int = 0,
        results: list[Task] = [];

    can start with Root entry { visit [-->]; }
}
