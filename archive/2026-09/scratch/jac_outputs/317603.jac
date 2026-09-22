"""
    How much percent is smaller number smaller than bigger number.
    If 1    -> both number equal size
    If 0.5  -> smaller number is half the size of bigger number
    """
def percental_difference_between_two_numbers(a: Any, b: Any) -> object {
    if (a <= b) {
        return (float(a) / b);
    } else {
        return (float(b) / a);
    }
}