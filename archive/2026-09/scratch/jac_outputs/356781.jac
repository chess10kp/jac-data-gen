"""Find the first path to a given key in a nested dict."""
def _findpath(dct: dict[str, object], key: str, path: tuple = ()) -> tuple[bool, tuple | None] {
    for (k, v) in dct.items() {
        if k == key {
            return (True, path + (k,));
        }
        if isinstance(v, dict) {
            (found, pth) = _findpath(v, key, path + (k,));
            if found {
                return (True, pth);
            }
        }
    }
    return (False, None);
}