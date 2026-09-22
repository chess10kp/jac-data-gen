"""Truncate a string to a specified maximum length."""
def truncate_string(string: str, max_length: int) -> str {
    if len(string) <= max_length {
        return string;
    }
    return string[:max_length];
}