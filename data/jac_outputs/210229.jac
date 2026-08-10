"""
    Given a integer, convert it to an roman numeral.
    https://en.wikipedia.org/wiki/Roman_numerals
    >>> tests = {"III": 3, "CLIV": 154, "MIX": 1009, "MMD": 2500, "MMMCMXCIX": 3999}
    >>> all(int_to_roman(value) == key for key, value in tests.items())
    True
    """
def int_to_roman(number: int) -> str {
    ROMAN = [
        (1000, "M"),
        (900, "CM"),
        (500, "D"),
        (400, "CD"),
        (100, "C"),
        (90, "XC"),
        (50, "L"),
        (40, "XL"),
        (10, "X"),
        (9, "IX"),
        (5, "V"),
        (4, "IV"),
        (1, "I")
    ];
    result = [];
    for (arabic, roman) in ROMAN {
        (factor, number) = divmod(number, arabic);
        result.append((roman * factor));
        if (number == 0) {
            break;
        }
    }
    return "".join(result);
}