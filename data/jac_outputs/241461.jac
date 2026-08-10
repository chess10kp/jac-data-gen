"""Convert a string with comma separated elements to a python list."""
def str2list(string: str) -> list[str] {
    return [str_.rstrip(" ").lstrip(" ") for str_ in string.split(",")];
}