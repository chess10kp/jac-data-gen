"""Given a list of strings, returns the longest common prefix."""
def max_common_prefix(a: list[str]) -> str {
    if not a {
        return '';
    }
    s1 = min(a);
    s2 = max(a);
    for (i, c) in enumerate(s1) {
        if c != s2[i] {
            return s1[:i];
        }
    }
    return s1;
}