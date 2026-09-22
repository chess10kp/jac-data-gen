"""Return the capital letter associated with the input integer (1=A, 2=B, etc.)."""
def integer_to_letter(i: int) -> str {
    return chr(i + 64);
}