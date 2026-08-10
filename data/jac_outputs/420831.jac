"""Get the key from the dict, returning the default if not found."""
def popget(d: dict[str, float], key: str, `default: float | None = None) -> float | None {
    try {
        return d.pop(key);
    } except KeyError {
        return `default;
    }
}