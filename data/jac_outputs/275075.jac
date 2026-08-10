"""Convert value into min & sec

    >>> int_convert_to_minute(123)
    '02:03'
    """
def int_convert_to_minute(value: int | str) -> str {
    min = int(int(value) / 60);
    sec = int(int(value) % 60);
    return f"{min:02d}:{sec:02d}";
}