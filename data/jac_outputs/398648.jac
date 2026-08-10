"""Recursively merge dictionaries."""
def merge(dict1: dict, dict2: dict) -> dict {
    for (key, val) in dict1.items() {
        if isinstance(val, dict) {
            dict2_node = dict2.setdefault(key, {});
            merge(val, dict2_node);
        } elif key not in dict2 {
            dict2[key] = val;
        }
    }
    return dict2;
}