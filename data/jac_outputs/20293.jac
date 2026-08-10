"""
    Return a string representing the sign of a numerical value, "+" for positive, "-" for negative,
    and "+/-" for 0.
    :param value: A numerical value.
    :return: The sign of that value as a string.
    """
def sign_string(value: Any) -> object {
    return "+" if (value > 0) else "-" if (value < 0) else "+/-";
}