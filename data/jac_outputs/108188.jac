"""Convert a decomposition rule tag into regex notation."""
def tag_to_regex(tag_name: str, tags: dict[str, list[str]]) -> str {
    if tag_name in tags {
        return r'\b(' + '|'.join(tags[tag_name]) + r')\b';
    }
    return '';
}