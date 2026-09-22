"""Break a line into a list of words.

Use a comma as a separator.
Strip leading and trailing whitespace.
"""
def get_words(line: str) -> list[str] {
    [word.strip() for word in line.split(',')]
}