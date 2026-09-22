"""
    Takes a number as input and returns the sum of the absolute value of each of the number's decimal digits.
    :param number: an integer value.
    :return: sum of the absolute value of each of the number's decimal digits.
    """
def sum_digits(number: Any) -> object {
    return sum(int(x) for x in str(abs(number)));
}