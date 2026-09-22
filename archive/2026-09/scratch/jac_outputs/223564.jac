"""Given any number of dicts, shallow copy and merge into a new dict."""
def merge_dicts(*dict_args: dict[str, int | str | float | bool | None]) -> dict[str, int | str | float | bool | None] {
    result = {};
    for dictionary in dict_args {
        result.update(dictionary);
    }
    return result;
}