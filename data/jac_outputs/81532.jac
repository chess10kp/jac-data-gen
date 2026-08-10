"""Turn tags into canonical space-delimited string representation."""
def tags_list_to_string(tags: list[str]) -> str {
    return ' '.join('[[%s]]' % tag if ' ' in tag else tag for tag in tags);
}