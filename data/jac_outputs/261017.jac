"""Translate R/L boarding-pass code to binary and return the integer value."""
def guesscol(code: str) -> int {
    code = code.translate(code.maketrans("RL", "10"));
    return int(code, 2);
}