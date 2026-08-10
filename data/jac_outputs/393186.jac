"""
    Recursively convert dict-like object (eg OrderedDict) into plain dict.
    Sorts list values.
    """
def normalise_dict(d: object) -> dict[str, object] {
    out = {};
    for (k, v) in dict(d).items() {
        if hasattr(v, "iteritems") {
            out[k] = normalise_dict(v);
        } elif isinstance(v, list) {
            out[k] = [];
            for item in sorted(v) {
                if hasattr(item, "iteritems") {
                    out[k].append(normalise_dict(item));
                } else {
                    out[k].append(item);
                }
            }
        } else {
            out[k] = v;
        }
    }
    return out;
}