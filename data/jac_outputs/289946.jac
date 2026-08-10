"""Validates that input give is between 1 and 10
        >>> validate_input(5)
        True
        >>> validate_input(-2)
        False
        >>> validate_input(12)
        False
        """
def validate_input(x: Any) -> object {
    x = int(x);
    if (1 <= x <= 10) {
        return True;
    } else {
        return False;
    }
}