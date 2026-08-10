"""This function ensures that the ``id`` keys in a list of dictionaries use string values."""
def convert_dict_id_values_to_strings(dict_list: list[dict[str, object]] | tuple[dict[str, object], ...] | dict[str, object] | None) -> list[dict[str, object]] {
    items = [dict_list] if isinstance(dict_list, dict) else dict_list;
    new_dict_list = [];
    for single_dict in items {
        if not isinstance(single_dict, dict) {
            raise TypeError(
                "The 'dict_list' argument must be a dictionary or a list of dictionaries."
            );
        }
        if 'id' in single_dict and not isinstance(single_dict.get('id'), str) {
            single_dict['id'] = str(single_dict.get('id'));
        }
        new_dict_list.append(single_dict);
    }
    return new_dict_list;
}