"""Convert uppercase ASCII letters in a string to lowercase."""
def lower(word: str) -> str {
    "".join(chr(ord(char) + 32) if 65 <= ord(char) <= 90 else char for char in word)
}