"""
Function to add two dictionaries by adding lists of matching keys.
"""
def merge_dicts_lists(parent_dict: dict[str, list[object]], merge_dict: dict[str, object]) -> dict[str, list[object]] {
    for key in merge_dict.keys() {
        if key in parent_dict {
            if not isinstance(merge_dict[key], list) {
                parent_dict[key] += [merge_dict[key]];
            } else {
                parent_dict[key] += merge_dict[key];
            }
        } elif not isinstance(merge_dict[key], list) {
            parent_dict[key] = [merge_dict[key]];
        } else {
            parent_dict[key] = merge_dict[key];
        }
    }
    return parent_dict;
}