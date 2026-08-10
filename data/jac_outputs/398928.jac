"""Find the longest string that is a prefix of all the strings."""
def common_prefix(strings: list[str]) -> str {
    if not strings {
        return '';
    }
    prefix = strings[0];
    for s in strings {
        if len(s) < len(prefix) {
            prefix = prefix[:len(s)];
        }
        if not prefix {
            return '';
        }
        for i in range(len(prefix)) {
            if prefix[i] != s[i] {
                prefix = prefix[:i];
                break;
            }
        }
    }
    return prefix;
}