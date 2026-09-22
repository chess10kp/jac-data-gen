"""Get brief description from paragraphs of command description."""
def get_brief_description(description: list[str]) -> str {
    if description {
        return description[0];
    } else {
        return 'No description available.';
    }
}