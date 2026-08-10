"""
    A utility method to tell if the provided line is
    a comment or not

    Parameters
    ----------
    str line: The line string in a file
    list comments: A list of potential comment keywords
    """
def is_comment(line: Any, comments: Any) -> object {
    return (line.lstrip(' ')[0] in comments);
}