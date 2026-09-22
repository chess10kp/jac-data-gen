"""
    Receives dictionary and cherry picks key values.
    Returns dictionary with only keys in the keys list.
    """
def cherrypick_dict(
    dictionary: dict[str, str | int | float | bool],
    keys: list[str]
) -> dict[str, str | int | float | bool] {
    return_dict: dict[str, str | int | float | bool] = dict();
    for (key, value) in dictionary.items() {
        if key in keys {
            return_dict[key] = value;
        }
    }
    return return_dict;
}