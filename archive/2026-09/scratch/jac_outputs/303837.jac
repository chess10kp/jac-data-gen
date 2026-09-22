"""
    Function to check if a condition is known and accounted for.

    Parameters
    ----------
    directory : string
        the name of a directory that is the condition to check for

    conditions : list of strings
        a list of known and accounted for conditions

    Returns
    -------
    directory : string or None
        either returns an unaccounted-for condition or returns None.
    """
def check_conditions(directory: Any, conditions: Any) -> object {
    for condition in conditions {
        if (condition in directory) {
            return None;
        }
    }
    return directory;
}