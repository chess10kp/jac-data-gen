"""Return font-weight CSS for viewed vs unviewed pages."""
def bold_viewed(val: int | str, viewed_pages: list[int | str]) -> str {
    weight = 'bold' if val in viewed_pages else 'normal';
    return 'font-weight: %s' % weight;
}