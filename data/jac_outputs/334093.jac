"""Return true if the character is part of a valid policy ID."""
def _allowed_char(char: str) -> bool {
    return char.isalnum() or char in {' ', '-', '.'};
}