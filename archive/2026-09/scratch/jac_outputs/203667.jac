"""Check whether target is the end of string."""
def endswith(string: str, target: str) -> bool {
    if not isinstance(string, str) {
        raise TypeError("param 'string' must be a string");
    }
    if not isinstance(target, str) {
        raise TypeError("param 'target' must be a string");
    }
    return string[len(target) * -1:] == target;
}