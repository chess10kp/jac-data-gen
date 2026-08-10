"""Adds html '<br>' to all '\n' linebreaks."""
def br(text: str) -> str {
    return text.replace("\n", "<br>\n");
}