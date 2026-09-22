"""Password Validation."""
def pwvalid(minCount: int | str, maxCount: int | str, char: str, pw: str) -> bool {
    return int(minCount) <= pw.count(char) <= int(maxCount);
}