"""Get the real value of the standard number.

    Args:
        std_num: The number you want to reduction.

    Returns:
        The real value of the number.
    """
glob STD_NUM_DIVISOR = 100000000;

def real_number(std_num: float) -> float {
    return float(std_num) / STD_NUM_DIVISOR;
}