"""Return encoded string by shifting every character by 5 in the alphabet."""
def encode_shift(s: str) -> str {
    return "".join([chr((ord(ch) + 5 - ord("a")) % 26 + ord("a")) for ch in s]);
}