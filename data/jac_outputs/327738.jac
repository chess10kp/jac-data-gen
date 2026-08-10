"""
Handles the tags
Checks if the tags are an array, if yes make them a comma-separated string
"""
def fix_tags(tags: str | list[str]) -> str {
    if isinstance(tags, list) {
        tags = ",".join(tags);
    }
    return tags;
}