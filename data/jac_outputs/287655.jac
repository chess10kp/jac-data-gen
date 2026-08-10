"""Shorten a string (with an ellipsis) if it is longer than certain length."""
def str_truncate(text: str, width: int = 64, ellipsis: str = "...") -> str {
    assert width >= 0;
    if len(text) <= width {
        return text;
    }
    if len(ellipsis) > width {
        ellipsis = ellipsis[:width];
    }
    return text[:max(0, width - len(ellipsis))] + ellipsis;
}