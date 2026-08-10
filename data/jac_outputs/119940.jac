"""Return list of tags from given string."""
def get_tags_from_string(tags_string: str) -> list[str] {
    tags = tags_string.split(', ') if tags_string else [];
    return [tag for tag in tags if tag];
}