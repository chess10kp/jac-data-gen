"""Joins dictionaries in a consitent way

For multiple occurences of a key the  value is defined by the first key : value pair.

Arguments:
    *args: list of parameter dictonaries

Returns:
    dict: the joined dictionary
"""
def joinParameter(*args: dict[str, str | int | float | bool]) -> dict[str, str | int | float | bool] {
    key_list = [x.keys() for x in args];
    n = len(args);
    keys = [];
    values = [];
    for i in range(n) {
        values = values + [args[i][k] for k in key_list[i] if k not in keys];
        keys = keys + [k for k in key_list[i] if k not in keys];
    }
    return {keys[i]: values[i] for i in range(len(keys))};
}