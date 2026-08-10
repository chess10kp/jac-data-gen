"""unionWith for Python, but modifying first dictionary instead of returning result"""
def update_with(
    left: dict[str, list],
    right: dict[str, list],
    default_value: list,
    upd_fn: Callable[[list, list], list]
) -> dict[str, list] {
    for (k, val) in right.items() {
        if k not in left {
            left[k] = default_value[:];
        }
        left[k] = upd_fn(left[k], val);
    }
    return left;
}