"""Decode dict."""
def decode_dict(d: dict[bytes, bytes | dict]) -> dict[str, str | dict] {
    result = {};
    for (key, value) in d.items() {
        if isinstance(key, bytes) {
            key = key.decode();
        }
        if isinstance(value, bytes) {
            result.update({key: value.decode()});
        } elif isinstance(value, dict) {
            result.update({key: decode_dict(value)});
        } else {
            result.update({key: value});
        }
    }
    return result;
}