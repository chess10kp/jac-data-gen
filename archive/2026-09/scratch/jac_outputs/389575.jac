"""Iterate a nested dict based on a list of keys."""
def iterate(source: dict | list, *keys: str | int) -> dict | list | int | str | float | bool {
    d = source;
    for k in keys {
        if isinstance(d, list) {
            d = d[int(k)];
        } elif k not in d {
            d[k] = {};
        } else {
            d = d[k];
        }
    }
    return d;
}