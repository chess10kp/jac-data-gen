"""Represent a dictionary with human-friendly text.

    Assuming d is of type dict, the output should be syntactically
    equivalent to repr(d), but with each key-value pair on its own,
    indented line.
    """
def pretty_dict_repr(d: dict[str, str | int | float | bool]) -> str {
    lines = ['    {0!r}: {1!r},'.format(k, v) for (k, v) in sorted(d.items())];
    return '\n'.join(['{'] + lines + ['}']);
}