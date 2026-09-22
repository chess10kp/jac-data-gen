"""Zip the arrays associated with the keys in two dictionaries"""
def zip_dicts(dict_a: dict[str, list], dict_b: dict[str, list]) -> list[dict] {
    combined = {};
    combined.update(dict_a);
    combined.update(dict_b);
    zipped_vals = zip(*combined.values());
    keys = list(combined.keys());
    out = [];
    for zv in zipped_vals {
        row = {k: v_ for (k, v_) in zip(keys, zv)};
        out.append(row);
    }
    return out;
}