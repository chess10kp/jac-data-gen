"""Truncates output if it is too long."""
def trunc(text: str, max_length: int = 2000) -> str {
    if len(text) <= max_length {
        return text;
    }
    return text[0:max_length - 3] + "...";
}