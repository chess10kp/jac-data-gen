"""A meta-feature that will produce the set difference of two boolean features
    (will have keys set to 1 only for those features that occur in the first set but not in the
    second).

    @rtype: dict
    @return: dictionary with keys for key occurring with the first feature but not the second, and \
        keys equal to 1
    """
def set_difference(tree: str, context: dict[str, dict[str, dict[str, int]]], attribs: list[str]) -> dict[str, int] {
    ret = {};
    for (key, val) in context['feats'][attribs[0]].items() {
        if key not in context['feats'][attribs[1]] {
            ret[key] = val;
        }
    }
    return ret;
}