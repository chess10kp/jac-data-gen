"""Get tagname without prefix"""
def tag_clean(n: str) -> str {
    if n[0] in '-~!' {
        return n[1:];
    }
    return n;
}