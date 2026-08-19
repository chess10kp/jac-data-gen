node Task {
    has title: str,
        done: bool = False,
        category: str = "other",
        priority: int = 1,
        estimated_minutes: int = 30;
}
