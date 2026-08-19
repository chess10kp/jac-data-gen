node Task {
    has title: str, done: bool = False, category: str = "other", priority: int = 3;
    can respond with ListTasks entry {
        if self.priority <= visitor.min_priority { visitor.results.append(self); }
    }
}
