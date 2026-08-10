"""
    Given a data_structure return the *first* value of the key from the first dict
    example:
        data_structure: [ { "id": 1, "name": "name1" }, { "id": 2, "name": "name2"} ]
        key: "id"
        return 1
    """
def get_value_for_key_from_json(key: str, data_structure: list | dict) -> int | str | float | bool | list | dict | None {
    if type(data_structure) == list {
        for v in data_structure {
            r = get_value_for_key_from_json(key, v);
            if r is not None {
                return r;
            }
        }
        return None;
    } elif type(data_structure) == dict {
        if key in data_structure {
            return data_structure[key];
        }
        for k in data_structure {
            v = data_structure[k];
            r = get_value_for_key_from_json(key, v);
            if r is not None {
                return r;
            }
        }
    }
    return None;
}