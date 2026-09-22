"""
    Return a number suitably formatted for display as currency, with
    thousands separated by commas and up to two decimal points.

    >>> format_currency(1000)
    '1,000'
    >>> format_currency(100)
    '100'
    >>> format_currency(999.95)
    '999.95'
    >>> format_currency(99.95)
    '99.95'
    >>> format_currency(100000)
    '100,000'
    >>> format_currency(1000.00)
    '1,000'
    >>> format_currency(1000.41)
    '1,000.41'
    >>> format_currency(23.21, decimals=3)
    '23.210'
    >>> format_currency(1000, decimals=3)
    '1,000'
    >>> format_currency(123456789.123456789)
    '123,456,789.12'
    """
def format_currency(value: int | float, decimals: int = 2) -> str {
    (number, decimal) = ('%%.%df' % decimals % value).split('.');
    parts = [];
    while len(number) > 3 {
        (part, number) = (number[-3:], number[:-3]);
        parts.append(part);
    }
    parts.append(number);
    parts.reverse();
    if int(decimal) == 0 {
        return ','.join(parts);
    } else {
        return ','.join(parts) + '.' + decimal;
    }
}