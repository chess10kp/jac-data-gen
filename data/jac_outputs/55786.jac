"""pack a string into a LCS."""
def LCS(value: str) -> bytes {
    return b'\x84' + str.encode(value) + b'\x00';
}