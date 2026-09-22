"""
    Quick function to tidy up lines in an ASCII file (split on spaces and strip consecutive spaces).

    Parameters
    ----------
    x : str
        String to split.
    separator : str, optional
        Give a separator to split on. Defaults to space.

    Returns
    -------
    y : list
        The split string.

    """
def split_string(x: Any, separator: Any = ' ') -> object {
    return [
        i.strip()
        for i in x.split(separator)
        if i.strip()
    ];
}