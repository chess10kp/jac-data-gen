"""Rounds a number to a specified number of decimal places.

    Args:
        num (float): The number to round.
        decimal (int, optional): The number of decimal places to round. Defaults to 2.

    Returns:
        float: The number with the specified decimal places rounded.
    """
def num_round(num: Any, decimal: Any = 2) -> object {
    return round(num, decimal);
}