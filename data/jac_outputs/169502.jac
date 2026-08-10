"""
If a dict contains callable (functions or classes) values, stringify_dict replaces them with their __name__ attributes.
Useful for logging the dictionary.
"""
def stringify_dict(d: dict[str, object]) -> dict[str, object] {
    str_d = {};
    for (k, v) in d.items() {
        if isinstance(v, dict) {
            str_d[k] = stringify_dict(v);
        } elif callable(v) {
            str_d[k] = getattr(v, "__name__");
        } elif isinstance(v, list) {
            str_d[k] = str(v);
        } else {
            str_d[k] = v;
        }
    }
    return str_d;
}