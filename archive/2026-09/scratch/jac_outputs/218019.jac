"""Find first object in a dictionary where object[field] is a list"""
def find_next_list_property(search_dict: Any, fields_to_check: Any) -> object {
    for (key, val) in search_dict.items() {
        for field in fields_to_check {
            if ((field in val) and isinstance(val[field], `list)) {
                return (key, field);
            }
        }
    }
    return (None, None);
}