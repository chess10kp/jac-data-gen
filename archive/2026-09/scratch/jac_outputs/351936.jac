"""Applies a given callable to the leaves of a given tree / set of nested dictionaries, returning the result (without
modifying the original dictionary)"""
def dict_map_leaves(nested_dicts: dict, func_to_call: Callable[[object], object]) -> dict {
    to_update = dict(nested_dicts);
    for (k, v) in nested_dicts.items() {
        if isinstance(v, dict) {
            to_update[k] = dict_map_leaves(v, func_to_call);
        } else {
            to_update[k] = func_to_call(v);
        }
    }
    return to_update;
}