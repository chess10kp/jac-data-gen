"""Replaces Dictionary Values whenver bad_val is encountered with good_val."""
def replace_dict_value[T](d: dict[str, T], bad_val: T, good_val: T) -> dict[str, T] {
    for (k, v) in d.items() {
        if v == bad_val {
            d[k] = good_val;
        }
    }
    return d;
}