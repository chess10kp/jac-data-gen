""" Filters those tasks where it's state is TASK_RUNNING.
    :param tasks: a list of mesos.cli.Task
    :return filtered: a list of running tasks
    """
def filter_running_tasks(tasks: Any) -> object {
    return [
        task
        for task in tasks
        if (task['state'] == 'TASK_RUNNING')
    ];
}