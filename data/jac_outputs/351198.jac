"""trim common prefixes"""
def trim_common_prefixes(strs: list[str], min_len: int = 0) -> tuple[int, list[str]] {
    trimmed = 0;
    if len(strs) > 1 {
        s1 = min(strs);
        s2 = max(strs);
        for i in range(len(s1) - min_len) {
            if s1[i] != s2[i] {
                break;
            }
            trimmed = i + 1;
        }
    }
    if trimmed > 0 {
        strs = [s[trimmed:] for s in strs];
    }
    return (trimmed, strs);
}