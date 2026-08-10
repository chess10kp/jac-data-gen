"""Calculate the ISBN check digit for 10-digit numbers. The number passed
    should not have the check bit included."""
def _calc_isbn10_check_digit(number: str) -> str {
    check = sum([(i + 1) * int(n) for (i, n) in enumerate(number)]) % 11;
    return 'X' if check == 10 else str(check);
}