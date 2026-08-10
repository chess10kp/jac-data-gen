"""If given number has only one digit, a new string with two spaces in the left is returned. Otherwise, a string without spaces is returned."""
def pad_number(num: int) -> str {
    pad = '  ' if num < 10 else '';
    return '%s%s' % (pad, num);
}