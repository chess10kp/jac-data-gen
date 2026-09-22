"""
    Return dictionary sorted using key. If no key provided sorted by dict keys.
    """
def sorted_dict(d: Any, key: Any = None, reverse: Any = False) -> object {
    if (key is None) {
        return `dict(sorted(d.items(), key=lambda (e: Any) { e[0]; }, reverse=reverse));
    }
    return `dict(sorted(d.items(), key=key, reverse=reverse));
}