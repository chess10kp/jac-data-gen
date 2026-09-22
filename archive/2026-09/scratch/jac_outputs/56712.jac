"""Remove carriage return and newline characters from text."""
def cr_strip(text: str) -> str {
    text = text.replace("\n", "");
    text = text.replace("\r", "");
    return text;
}