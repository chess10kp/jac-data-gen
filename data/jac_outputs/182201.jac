"""Return a safe escaped version of the string."""
def good_str(x: str) -> str {
    return repr(str(x))[1:-1];
}