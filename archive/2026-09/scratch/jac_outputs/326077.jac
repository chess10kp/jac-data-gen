"""counts the number of times the pattern appears in the string
    for example:
        count_in_str("a", "abcaabc") returns 3
        count_in_str("ab", "abcaabc") return 2"""
def count_in_str(pattern: Any, str: Any) -> object {
    c = 0;
    sp = len(pattern);
    while (len(str) >= sp) {
        slice = str[:sp];
        if (pattern == slice) {
            c += 1;
        }
        str = str[1:];
    }
    return c;
}