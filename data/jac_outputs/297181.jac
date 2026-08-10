"""Returns a list of task requests."""
def task_request_statistics(contributions: list[dict[str, str]]) -> dict[str, list[dict[str, str]]] {
    task_requests = [
        contribution for contribution in contributions
        if "task" in contribution["category"]
    ];
    return {"task_requests": task_requests};
}