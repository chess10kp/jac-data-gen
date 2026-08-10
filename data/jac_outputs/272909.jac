"""Prints all the elements in a tuple separated by a given separator, default ' '."""
def print_tuple(*_args: str | int | float | bool, _separator: str = ' ') -> str {
    _separator.join(map(lambda (_x: str | int | float | bool) { str(_x); }, _args))
}