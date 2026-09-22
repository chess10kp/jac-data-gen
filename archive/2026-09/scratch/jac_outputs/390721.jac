"""
Given any number of dicts, shallow copy and merge into a new dict,
precedence goes to key value pairs in latter dicts.
"""
def merge_dicts(
    *dict_args: dict[str, str | int | float | bool | list | dict]
) -> dict[str, str | int | float | bool | list | dict] {
    result: dict[str, str | int | float | bool | list | dict] = {};
    for dictionary in dict_args {
        result.update(dictionary);
    }
    return result;
}