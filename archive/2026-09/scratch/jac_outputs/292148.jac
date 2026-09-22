"""
    Gets the nation of a number.
    :param number: The number to get the nation from.
    :return: The number's nation.
    """
def get_number_nation(number: Any) -> str {
    return "000s" if (len(str(number)) <= 2) else f"{str(number)[-3]}00s";
}