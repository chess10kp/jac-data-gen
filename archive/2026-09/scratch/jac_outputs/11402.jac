""" Converts a string to list of tokens. """
def tokenize(s: str) -> list[str] {
    return s.replace('(', ' ( ').replace(')', ' ) ').split();
}