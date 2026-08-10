"""Return column letter given number."""
def col_letter(col: int) -> str {
    chr(ord("A") + col - 1)
}