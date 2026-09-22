"""
    Return a string formatted representation of the given process state

    :param process_state: the process state
    :return: string representation of process state
    """
def format_process_state(process_state: Any) -> object {
    return '{}'.format(process_state.capitalize() if process_state else None);
}