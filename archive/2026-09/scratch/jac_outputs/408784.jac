"""Checks whether a phrase contains no repeated words."""
def is_simple_passphrase(phrase: list[str]) -> bool {
    return not any(phrase.count(word) > 1 for word in phrase);
}