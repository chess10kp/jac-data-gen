""" Combines hasattr/getattr to return a default if hasattr fail."""
def hasgetattr(`obj: object, attr: str, `default: object = None) -> object {
    if not hasattr(`obj, attr) {
        return `default;
    }
    return getattr(`obj, attr);
}