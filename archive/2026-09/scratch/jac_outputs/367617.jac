"""Starts with a 0 or 1 length palindrome and try to grow bigger."""
def grow(string: str, start: int, end: int) -> tuple[int, int] {
    while start > 0
        and end < len(string)
        and string[start - 1].upper() == string[end].upper() {
        start -= 1;
        end += 1;
    }
    return (start, end);
}