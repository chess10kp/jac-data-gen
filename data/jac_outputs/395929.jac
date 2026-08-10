"""
    Takes a dict with nested lists and dicts, and searches all dicts for a key of the field provided,
    returning a list of the values.
    """
def get_recursively(search_dict: dict[str, object], field: str) -> list[object] {
    fields_found: list[object] = [];
    for (key, value) in search_dict.items() {
        if key == field {
            fields_found.append(value);
        } elif isinstance(value, dict) {
            fields_found.extend(get_recursively(value, field));
        } elif isinstance(value, list) {
            for item in value {
                if isinstance(item, dict) {
                    fields_found.extend(get_recursively(item, field));
                }
            }
        }
    }
    return fields_found;
}