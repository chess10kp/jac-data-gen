"""Recursively merge elements of argument b into argument a."""
def merge_map(a: list | dict, b: list | dict) -> list | dict {
    if isinstance(a, list) and isinstance(b, list) {
        return a + b;
    }
    if not isinstance(a, dict) or not isinstance(b, dict) {
        return b;
    }
    for key in b.keys() {
        a[key] = merge_map(a[key], b[key]) if key in a else b[key];
    }
    return a;
}