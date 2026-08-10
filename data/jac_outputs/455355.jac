"""Recursively removes `None` values from `dictionary`."""
def clean_dict(dictionary: dict) -> dict {
    for (key, value) in list(dictionary.items()) {
        if isinstance(value, dict) {
            clean_dict(value);
        } elif value is None {
            dictionary.pop(key);
        }
    }
    return dictionary;
}