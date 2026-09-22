"""Returns a new dictionary with keys."""
def inclusive(dictionary: dict[str, object], *keys: str) -> dict[str, object] {
    return {key: value for (key, value) in dictionary.items() if key in keys};
}