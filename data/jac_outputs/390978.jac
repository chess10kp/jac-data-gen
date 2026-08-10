"""Given a list of letters, remove any empty strings.
    >>> remove_blanks(['a', '', 'b', '', 'c'])
    ['a', 'b', 'c']
    """
def remove_blanks(letters: list[str]) -> list[str] {
    return [letter for letter in letters if letter != ""];
}