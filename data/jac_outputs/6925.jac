"""Given a list of (word,tag) pairs, return words tagged with the given tag type prefix."""
def get_tag_type(tagtype: str, pairs: list[tuple[str, str]]) -> list[str] {
    return [w for (w, tag) in pairs if tag.startswith(tagtype)];
}