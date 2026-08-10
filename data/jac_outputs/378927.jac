"""Convert all characters to lowercase from list of tokenized words"""
def to_lowercase(words: list[str]) -> list[str] {
    return [word.lower() for word in words];
}