"""Concatenate a list of values to a readable string."""
def values_list_repr(values: list[str | int | float]) -> str {
    return "'{}' or '{}'".format("', '".join([str(i) for i in values[:-1]]), values[-1]);
}