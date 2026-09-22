"""
    truncate a given number to the chosen decimal place
    """
def truncate(number: Any, decimals: Any = 0) -> object {
    multiplier = 10 ** decimals;
    return (int((number * multiplier)) / multiplier);
}