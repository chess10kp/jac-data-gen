"""Recursively save the dict."""
def _save_dict(`obj: dict[str, object]) -> dict[str, object] {
    result = type(`obj)();
    for (k, v) in `obj.items() {
        if isinstance(v, dict) {
            result[k] = _save_dict(v);
        } elif hasattr(v, 'numpy') {
            result[k] = getattr(v, 'numpy')();
        } else {
            result[k] = v;
        }
    }
    return result;
}