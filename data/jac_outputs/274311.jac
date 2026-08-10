"""return the last (rightmost) part of a namespace or namespace-qualified proc"""
def doublecolon_tail(string: str) -> str {
    last_colons = string.rfind("::");
    if last_colons >= 0 {
        return string[last_colons + 2:];
    }
    return string;
}