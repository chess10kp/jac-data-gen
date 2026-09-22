"""Formats a dictionary into a string of key=value pairs."""
def format_dictionary(
    adict: dict[str, str | int | float | bool],
    sep: str = ', ',
    sort_first: bool = True
) -> str {
    preprocess = sorted if sort_first else lambda (x: list[tuple[str, str | int | float | bool]]) { x; };
    return sep.join('{}={}'.format(k, v) for (k, v) in preprocess(iter(adict.items())));
}