"""Convert a list of dicts to a dict keyed by a common field (duplicates overwritten)."""
def list_to_dict(list_to_convert: list[dict[str, str]], key_name: str) -> dict[str, dict[str, str]] {
    converted_dict = dict();
    if list_to_convert {
        for item in list_to_convert {
            converted_dict[item[key_name]] = item;
        }
    }
    return converted_dict;
}