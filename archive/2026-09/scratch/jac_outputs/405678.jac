"""The index of the pattern in lexicographically ordered k-mers."""
def patternToIndex(pattern: str) -> int {
    if len(pattern) == 1 {
        match pattern {
            case 'A':
                return 0;
            case 'C':
                return 1;
            case 'G':
                return 2;
            case 'T':
                return 3;
        }
    }
    last_char = pattern[-1:];
    prefix = pattern[:-1];
    return 4 * patternToIndex(prefix) + patternToIndex(last_char);
}