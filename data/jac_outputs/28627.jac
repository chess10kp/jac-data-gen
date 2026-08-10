"""Returns the maximum length of the substring ending at p that is a suffix."""
def suffix_length(needle: str, p: int) -> int {
    length = 0;
    j = len(needle) - 1;
    for i in reversed(range(p + 1)) {
        if needle[i] == needle[j] {
            length += 1;
        } else {
            break;
        }
        j -= 1;
    }
    return length;
}