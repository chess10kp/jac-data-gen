"""
    Converts a list into a dict.
    """
def list_to_dict(items: list[str], value: int | str | list | dict) -> dict[str, int | str | list | dict] {
    key = items.pop();
    result = {};
    bracket_index = key.find('[');
    if bracket_index > 0 {
        value = [value];
    }
    result[key] = value;
    if items {
        result = list_to_dict(items, result);
    }
    return result;
}