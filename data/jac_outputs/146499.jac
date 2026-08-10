"""Check for a valid birth year."""
def is_valid_byr(birthyear: str) -> bool {
    return birthyear.isdigit() and 1920 <= int(birthyear) <= 2002;
}