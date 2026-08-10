"""Split a string using multiple separator characters."""
def multiple_split(
    source_string: str, separators: str, split_by: str = '\n'
) -> list[str] {
    translate_to = split_by * len(separators);
    translation = str.maketrans(separators, translate_to);
    return source_string.translate(translation).split(split_by);
}