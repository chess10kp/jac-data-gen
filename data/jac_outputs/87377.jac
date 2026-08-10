"""Will take a dictionary, where *potentially* some values are lists. Will return a list of dictionaries
with no lists, where each possible list member combination is included."""
def _generateParams(param_dict: dict[str, str | int | float | list[str | int | float]]) -> list[dict[str, str | int | float | list[str | int | float]]] {
    keys = param_dict.keys();
    list_key = None;
    for key in keys {
        if isinstance(param_dict[key], list) {
            list_key = key;
            break;
        }
    }
    if list_key is None {
        return [param_dict];
    }
    new_dicts = [];
    for list_val in param_dict[list_key] {
        new_dict = {};
        for key in keys {
            if key is not list_key {
                new_dict[key] = param_dict[key];
            } else {
                new_dict[key] = list_val;
            }
        }
        new_dicts.append(new_dict);
    }
    ret = [];
    for dic in new_dicts {
        ret += _generateParams(dic);
    }
    return ret;
}