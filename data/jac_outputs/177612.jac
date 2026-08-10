"""Recursively access nested dictionaries."""
def safe_lookup(dictionary: dict | None, *keys: str, `default: str | int | float | bool | dict | list | None = None) -> str | int | float | bool | dict | list | None {
    if dictionary is None {
        return `default;
    }
    for key in keys {
        dictionary = dictionary.get(key);
        if dictionary is None {
            return `default;
        }
    }
    return dictionary;
}