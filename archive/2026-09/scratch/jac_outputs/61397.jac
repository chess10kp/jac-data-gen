"""
    Args:
        token (str): word being evaluated
    Returns:
        binary: True if last character is a period, false if not.
    """
def period_at_end(token: str) -> bool {
    return list(token).pop() is ".";
}