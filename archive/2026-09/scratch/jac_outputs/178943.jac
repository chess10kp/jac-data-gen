"""Returns i + the ordinal indicator for the number.

    Example: ordinal(3) => '3rd'
    """
def ordinal(i: int | str) -> str {
    i = int(i);
    if i % 100 in (11, 12, 13) {
        return '%sth' % i;
    }
    ord = 'th';
    last_digit = i % 10;
    if last_digit == 1 {
        ord = 'st';
    } elif last_digit == 2 {
        ord = 'nd';
    } elif last_digit == 3 {
        ord = 'rd';
    }
    return '%s%s' % (i, ord);
}