"""
    Replaces all the occurrences of a substring into a new one

    Parameters
    ----------
    text : str
        the string where to operate
    old : str
        the substring to be replaced
    new : str
        the new substring

    Returns
    -------
    str
        The new string
    """
def strrep(text: str, old: str, new: str) -> str {
    text.replace(old, new)
}