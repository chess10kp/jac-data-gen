""""Given a string, return a list of index positions where a blank space occurs.
    >>> space_list("    abc ")
    [0, 1, 2, 3, 7]
    """
def space_list(line: str) -> list[int] {
    return [idx for (idx, car) in enumerate(list(line)) if car == " "];
}