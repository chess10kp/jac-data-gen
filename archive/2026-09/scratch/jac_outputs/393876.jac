"""Extract values for a specific key from a list of dictionaries."""
def extract_key_values_from_dict_list(
    key_name: str,
    dict_list: list[dict[str, int | str]] | dict[str, int | str],
    exclude_if_present: str | None = None,
    convert_to_string: bool = True
) -> list[int | str] {
    value_list = [];
    items = [dict_list] if isinstance(dict_list, dict) else dict_list;
    for single_dict in items {
        if key_name in single_dict {
            skip_dict = exclude_if_present is not None and exclude_if_present in single_dict;
            if not skip_dict {
                key_value = str(single_dict.get(key_name)) if convert_to_string else single_dict.get(key_name);
                value_list.append(key_value);
            }
        }
    }
    return value_list;
}