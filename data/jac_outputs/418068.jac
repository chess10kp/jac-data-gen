"""Return substring between 'first' and 'last'."""
def find_between(string: str, first: str, last: str) -> str {
    try {
        start = string.index(first) + len(first);
        end = string.index(last, start);
        return string[start:end];
    } except ValueError {
        return "";
    }
}