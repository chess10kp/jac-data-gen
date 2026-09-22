"""Replace quotes with their ASCII character representation."""
def ascii_replace(text: str) -> str {
    text = text.replace("'", "&#39;");
    text = text.replace("[&#39;", "['");
    text = text.replace("&#39;]", "']");
    return text;
}