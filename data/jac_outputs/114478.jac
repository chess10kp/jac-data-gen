"""
    Weight the priority to prefer smaller resource requests.
    As a task stays longer in the queue, increase priority.

    Best priority is 0, worse increases to infinity.

    Args:
        resources (dict): resources dict
        time_in_queue (float): the time this task has spent in the queue

    Returns:
        float: priority
    """
def sched_prio(resources: Any, time_in_queue: Any = 0) -> object {
    return max(0, (sum(resources.values()) - (time_in_queue / 600)));
}