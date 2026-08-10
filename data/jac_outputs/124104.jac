"""Returns all the tokens from a string, separated by a given separator, default ' '"""
def tokens(_s: str, _separator: str = ' ') -> list[str] {
    return _s.strip().split(_separator);
}