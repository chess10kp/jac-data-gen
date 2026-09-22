"""find all used keys that are used in a list of dictionaries"""
def get_keys_from_dict_list(elements: Any) -> object {
    keys = [];
    for element in elements {
        element_keys = element.keys();
        for key in element_keys {
            if not (key in keys) {
                keys.append(key);
            }
        }
    }
    return keys;
}