"""
    Return the exit code (exitCode) and exit message (exitMsg).
    E.g. (0, 'OK').

    :param jobreport_dictionary:
    :return: exit_code, exit_message
    """
def get_exit_info(jobreport_dictionary: Any) -> object {
    return (jobreport_dictionary['exitCode'], jobreport_dictionary['exitMsg']);
}