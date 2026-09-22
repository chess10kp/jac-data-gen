"""Return a regular expression to match a <bos case="..."/> element.

    grp: boolean indicating whether to retain case value subgroup.
    returns: regular expression text
    """
def bos_markup(grp: Any = True) -> object {
    return '<bos +case="({0}.+?)"/>'.format("" if grp else "?:");
}