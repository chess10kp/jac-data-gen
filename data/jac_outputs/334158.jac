"""Helper function that returns the substring of a string until a certain pattern."""
def until(val: str, substr: str) -> str {
    if substr not in val {
        return val;
    }
    return val[:val.find(substr)];
}