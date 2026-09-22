"""
    Merge a list of nested dicts into a single dict
    """
def merge_nested_dict(dicts: list[dict[str, dict[str, str | int | float]]]) -> dict[str, dict[str, str | int | float]] {
    merged_dict = {};
    for d in dicts {
        for key in d.keys() {
            for subkey in d[key].keys() {
                if key not in list(merged_dict.keys()) {
                    merged_dict[key] = {subkey: {}};
                }
                merged_dict[key][subkey] = d[key][subkey];
            }
        }
    }
    return merged_dict;
}