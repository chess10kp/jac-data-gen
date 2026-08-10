"""Return the value for key from a dictionary, or None if missing."""
def get_item(dictionary: dict[str, str | int | float | bool], key: str) -> str | int | float | bool | None {
    return dictionary.get(key, None);
}