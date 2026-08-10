"""Returns true if the input is one of: list``, ``unnamedtuple``, dict``,
    or ``namedtuple``. Note that this definition is different from tf's is_nested
    where all types that are ``collections.abc.Sequence`` are defined to be nested.
    """
def is_nested(value: list[int] | tuple[int, ...] | dict[str, int] | int | float | str | bool) -> bool {
    return isinstance(value, (list, tuple, dict));
}