"""Return a sort key for a given task."""
def task_key(task: tuple[Callable, tuple]) -> tuple[str, tuple] {
    (function, args) = task;
    return (function.__name__, args);
}