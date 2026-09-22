"""Merges two dictionaries non-destructively, combining values on duplicate keys."""
def merge_dict(
    d1: int | dict[str, int],
    d2: int | dict[str, int] | None,
    merge: Callable[[int | dict[str, int], int | dict[str, int] | None], int | dict[str, int]] = lambda (x: int, y: int) { y; }
) -> int | dict[str, int] {
    if not isinstance(d1, dict) {
        return merge(d1, d2);
    }
    result = dict(d1);
    if d2 is None {
        return result;
    }
    d2_dict = d2 as dict[str, int];
    for (k, v) in list(d2_dict.items()) {
        if k in result {
            result[k] = merge_dict(result[k], v, merge=merge);
        } else {
            result[k] = v;
        }
    }
    return result;
}