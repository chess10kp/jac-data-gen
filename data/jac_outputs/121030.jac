"""
    Format a number with commas.
    """
def comma_filter(value: Any) -> object {
    return '{:,}'.format(value);
}