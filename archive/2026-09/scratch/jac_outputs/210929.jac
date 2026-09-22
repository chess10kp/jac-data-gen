"""
    Find a key in the wkt, return it's name and items.

    .. versionadded:: 9.2
    """
def find_key(wkt: list[object], k: str | int) -> tuple[str, list[object]] {
    for w in wkt {
        if (`type(w) is dict) {
            d = w as dict[str, object];
            if d['key'] == k {
                return (d['name'] as str, d.get('items', []) as list[object]);
            }
            (name, items) = find_key(d.get('items', []) as list[object], k);
            if name {
                return (name, items);
            }
        }
    }
    return ('', []);
}