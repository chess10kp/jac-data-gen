"""Invert a dictionary."""
def invert_dictionary(dictionary: dict[str, str]) -> dict[str, str] {
    return {v: k for (k, v) in dictionary.items()};
}