"""Sort returned attribute values."""
def normalize_attributes(d: dict | None) -> dict | None {
    if d is None {
        return None;
    }
    r = {};
    for (key, value) in d.items() {
        if isinstance(value, list) {
            r[key] = sorted(value);
        } else {
            r[key] = value;
        }
    }
    return r;
}