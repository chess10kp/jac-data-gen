"""Return the merged value containing the partial combined calculation."""
def merge_partial(a: int | float | dict[str, object], b: int | float | dict[str, object]) -> int | float | dict[str, object] {
    if hasattr(a, '__add__') {
        return (a + b) as int | float | dict[str, object];
    }
    a_dict = a as dict[str, object];
    b_dict = b as dict[str, object];
    for (key, val) in b_dict.items() {
        if key not in a_dict {
            a_dict[key] = val;
        } else {
            a_dict[key] = merge_partial(
                a_dict[key] as int | float | dict[str, object],
                val as int | float | dict[str, object]
            );
        }
    }
    return a_dict;
}