"""Return control codes to set or unset XOR mode text."""
def OVER(n: int) -> str {
    return "".join((chr(21), chr(int(n))));
}