"""Abbreviate word."""
def abbr(S: str | None, max: int, ellipsis: str = '...') -> str {
    if S is None {
        return '???';
    }
    if len(S) > max {
        return (ellipsis and S[:(max - len(ellipsis))] + ellipsis) or S[:max];
    }
    return S;
}