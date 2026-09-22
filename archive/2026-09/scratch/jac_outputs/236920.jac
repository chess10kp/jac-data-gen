"""Calculate the check digit."""
def calc_check_digit(number: Any) -> object {
    if (number[10:13] <= '100') {
        weights = (14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2);
        total = sum((int(n) * w) for (n, w) in zip(number, weights));
        return str((total % 11 % 10));
    }
    weights = (2, 7, 6, 5, 4, 3, 2, 7, 6, 5, 4, 3, 2);
    total = sum((int(n) * w) for (n, w) in zip(number, weights));
    return str((-total % 11 % 10));
}