""" Check whether n is a power of 2 """
def is_power_of_two(n: Any) -> object {
    return ((n != 0) and ((n & (n - 1)) == 0));
}