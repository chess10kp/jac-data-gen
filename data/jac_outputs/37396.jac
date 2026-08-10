"""Combine two counts dictionaries."""
def combine_counts(counts1: dict[str, int], counts2: dict[str, int]) -> dict[str, int] {
    ret = counts1;
    for (key, val) in counts2.items() {
        if key in ret {
            ret[key] += val;
        } else {
            ret[key] = val;
        }
    }
    return ret;
}