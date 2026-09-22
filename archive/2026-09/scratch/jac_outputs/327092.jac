"""Calculate the check digit. The number passed should not have the
check digit included."""
def calc_check_digit(number: str) -> str {
    check = 11 - sum((8 - i) * int(n) for (i, n) in enumerate(number)) % 11;
    return '0' if check == 10 else str(check);
}