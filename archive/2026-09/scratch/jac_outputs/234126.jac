"""
    Check if a format (string) contains a date.
    (It currently check if the string contains tokens from the simpledateformat
    https://docs.oracle.com/javase/7/docs/api/java/text/SimpleDateFormat.html
    that represent, years, months, days).

    :param format: A string format representing a simple date format.
    :type format: str
    :return: True if values part of a date are contained in the format string.
    :rtype: bool
    """
def _contains_date(format: Any) -> object {
    part_of_date_tokens = "GyYMwWdDFEu";
    for token in part_of_date_tokens {
        if (token in format) {
            return True;
        }
    }
    return False;
}