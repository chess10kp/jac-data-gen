"""Dump a dict to a str,
    with keys in alphabetical order.
    """
def alphadump(d: Any, indent: Any = 2, depth: Any = 0) -> object {
    sep = "\n" + (" " * depth * indent);
    return "".join(
        "{}: {}{}".format(
            k,
            alphadump(d[k], depth=(depth + 1))
                if isinstance(d[k], `dict)
                else str(d[k]),
            sep
        ) for k in sorted(d.keys())
    );
}