"""Create a new dictionary without keys mapped to null values."""
def remove_null_values(dictionary: dict) -> dict {
    if isinstance(dictionary, dict) {
        return {
            k: v
            for (k, v) in dictionary.items()
            if v is not None
        };
    }
    return dictionary;
}