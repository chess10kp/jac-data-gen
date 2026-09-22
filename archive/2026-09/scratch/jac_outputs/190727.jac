"""Format text."""
def _format_text(text: str) -> str {
    text = text.replace("-", "--");
    text = text.replace("_", "__");
    text = text.replace(" ", "_");
    return text;
}