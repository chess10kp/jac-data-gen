import unicodedata;

"""Checks whether `chars` is a whitespace character."""
def is_whitespace(char: str) -> bool {
    if char in (" ", "\t", "\n", "\r") {
        return True;
    }
    return unicodedata.category(char) == "Zs";
}