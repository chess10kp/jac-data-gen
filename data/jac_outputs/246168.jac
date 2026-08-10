"""
    Check if the input number is a power of 2.
    """
def is_power_of_2(num: Any) -> object {
    return ((num != 0) and ((num & (num - 1)) == 0));
}