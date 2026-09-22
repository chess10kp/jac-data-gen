"""Merge dicts whose values are int.

    if key is present in multiple dict, choose the max.

    Args:
        dicts (list): list of dicts to merge

    Retrun:
        (dict) merged dict
    """
def max_dict(dicts: list[dict[str, int]]) -> dict[str, int] {
    ret = {};
    for cur_dict in dicts {
        for (key, value) in cur_dict.items() {
            ret[key] = max(d.get(key, 0) for d in dicts);
        }
    }
    return ret;
}