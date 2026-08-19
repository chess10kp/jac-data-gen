def display_value(value: float, thousands_separator: str = ',', decimal_separator: str = '.') -> str:
    """
    Display a value as a string with specific format.

    Parameters
    ----------
    value : float
        Value to display.
    thousands_separator : str
        The separator used to separate thousands.
    decimal_separator : str
        The separator used to separate decimal values.

    Returns
    -------
    str

    Examples
    --------
    >>> display_value(1255000, thousands_separator=',')
    '1,255,000'

    """
    value_str = '{:,}'.format(value).replace(',', '/thousands/').replace('.', '/decimal/')
    return value_str.replace('/thousands/', thousands_separator).replace('/decimal/', decimal_separator)

assert display_value(1) == '1'
assert display_value(1234567) == '1,234,567'
assert display_value(1255000.25) == '1,255,000.25'
assert display_value(1255000, '.') == '1.255.000'
assert display_value(1234567.89) == '1,234,567.89'
assert display_value(125) == '125'
assert display_value(125500) == '125,500'
assert display_value(1234.56, '.', ',') == '1.234,56'
assert display_value(10000) == '10,000'
assert display_value(1255000.401) == '1,255,000.401'
assert display_value(123456.78) == '123,456.78'
assert display_value(1255000.1) == '1,255,000.1'
assert display_value(0.1255) == '0.1255'
assert display_value(1255000.000000012) == '1,255,000.000000012'
assert display_value(125500000) == '125,500,000'
assert display_value(12345678.901) == '12,345,678.901'
assert display_value(12) == '12'
assert display_value(12550000) == '12,550,000'
assert display_value(123456789.01, ',', 'x') == '123,456,789x01'
assert display_value(12345678.9) == '12,345,678.9'
assert display_value(123456) == '123,456'
assert display_value(1255000.4012) == '1,255,000.4012'
assert display_value(1255000.123, ',', '.') == '1,255,000.123'
assert display_value(1255000, ',') == '1,255,000'
assert display_value(0) == '0'
assert display_value(1255000) == '1,255,000'
assert display_value(1000) == '1,000'
assert display_value(12345678) == '12,345,678'
assert display_value(12345) == '12,345'
assert display_value(1255000.4) == '1,255,000.4'
assert display_value(1255000, ',', '.') == '1,255,000'
assert display_value(1255000.123) == '1,255,000.123'
assert display_value(1234.56, ',', '.') == '1,234.56'
assert display_value(1234) == '1,234'
assert display_value(1255000000) == '1,255,000,000'
assert display_value(0.123456789) == '0.123456789'
