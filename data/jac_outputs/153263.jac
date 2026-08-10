"""
    Converts a numeric value to usd-formatted string, for printing and display purposes.

    Param: my_price (int or float) like 4000.444444

    Example: to_usd(4000.444444)

    Returns: $4,000.44
    """
def to_usd(my_price: Any) -> object {
    return f"${my_price:,.2f}";
}