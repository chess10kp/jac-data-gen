"""
    Checks if one of the failed tasks is from an excluded playbook and if so removes it from the list.

    Args:
        failed_tasks: A list of failed tasks.
        playbook_exclusion: A list of names of playbooks to exclude.

    Returns:
        The modified list.
    """
def remove_exclusion(failed_tasks: list, playbook_exclusion: list) -> object {
    for playbook in playbook_exclusion {
        for task in failed_tasks {
            if (playbook in task['Playbook Name']) {
                failed_tasks.remove(task);
            }
        }
    }
    return failed_tasks;
}