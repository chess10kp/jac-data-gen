"""Format a float to a precision of 3, without zeroes or dots."""
def float_format(number: int | float) -> str {
    return ("%.3f" % number).rstrip('0').rstrip('.');
}