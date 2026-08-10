"""Set first character of each word to upper case."""
def first_upper_case(words: list[str]) -> list[str] {
    return [w.capitalize() for w in words];
}