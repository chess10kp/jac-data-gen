"""Formats a number as a dollar and cent value with alternatives for None and 0."""
def formatDollarsCents(
    d: float | int | None, noneValue: str = '', zeroValue: str = '$0.00'
) -> str {
    if d is None {
        return noneValue;
    } elif d == 0 {
        return zeroValue;
    }
    return '${:.2f}'.format(d);
}