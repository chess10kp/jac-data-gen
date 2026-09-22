"""
    Compute the difference of largest and smallest data point.
    """
def span(data: list[int | float], **kwargs: bool) -> int | float {
    return max(data) - min(data);
}