def strStr(haystack: str, needle: str) -> int {
    length_h = len(haystack);
    length_n = len(needle);
    for i in range(length_h - length_n + 1) {
        if haystack[i:i + length_n] == needle {
            return i;
        }
    }
    return -1;
}