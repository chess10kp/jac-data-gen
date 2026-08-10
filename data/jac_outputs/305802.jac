""" Returns true if a number is a power of two """
def is_power2(num: Any) -> object {
    return ((num != 0) and ((num & (num - 1)) == 0));
}