"""Convert string value to proper JSON type."""
def to_json_type(v: str) -> str | bool | int | float {
    try {
        if v.lower() in ("false", "true") {
            return True if v.lower() == "true" else False;
        } elif v.isdigit() {
            return int(v);
        } elif v.replace(".", "").isdigit() {
            return float(v);
        }
    } except AttributeError {
        raise ValueError(("Conversion to JSON failed for: %s" % v));
    }
    return v;
}