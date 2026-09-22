"""this function is used for converting a `10` based number to any other base!

    Args:
        num (int): your base 10 number.
        base (int): your wanted base for output.
        numerals (str, optional): numbers and alphabet which is used for converting number. Defaults to "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".

    Returns:
        str: your base-10 inputted number converted to the base you inputted
    """
def baseTenToOther(
    num: int, base: int, numerals: str = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
) -> object {
    return (
        ((num == 0) and numerals[0])
        or (
            baseTenToOther((num // base), base, numerals).lstrip(numerals[0])
            + numerals[(num % base)]
        )
    );
}