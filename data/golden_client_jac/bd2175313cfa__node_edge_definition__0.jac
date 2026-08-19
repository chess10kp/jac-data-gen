node Task {
    has title: str,
        done: bool = False,
        category: str = "other";

    can respond with ListTasks entry {
        visitor.results.append(self);
    }
}
