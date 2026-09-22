"""Return a dict."""
def dict_diff(d1: dict[str, int], d2: dict[str, int]) -> dict[str, int] {
    d: dict[str, int] = {};
    keys = set(d1.keys()) | set(d2.keys());
    for k in keys {
        if k not in d1 {
            d1[k] = 0;
        } elif k not in d2 {
            d2[k] = 0;
        }
        d[k] = d1[k] - d2[k];
    }
    return d;
}