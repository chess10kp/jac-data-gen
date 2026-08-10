"""Exclude non-alphanumeric tokens from a list of tokens."""
def only_alpha(tokens: list[str]) -> list[str] {
    [token for token in tokens if token.isalpha()]
}