"""
Filters a dictionary to all elements in a given iterable.
"""
def filter_dict(it: list[object] | set[object] | tuple[object, ...], d: dict[object, object] | None) -> dict[object, object] {
    if d is None {
        return {};
    }
    return {k: v for (k, v) in d.items() if k in it};
}