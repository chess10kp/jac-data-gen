"""Formats args and kwargs the way they look in a function call."""
def format_args(args: list[int | str | float | bool], kwargs: dict[str, int | str | float | bool]) -> str {
    return ', '.join(
        [repr(arg) for arg in args]
        + ['%s=%r' % item for item in sorted(kwargs.items())]
    );
}