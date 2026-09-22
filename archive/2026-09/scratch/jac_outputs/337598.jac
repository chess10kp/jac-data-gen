"""
Remove line breaks and other characters that might mess up table.
"""
def sanitize_field(field_text: str) -> str {
    strip_chars = ["\r", "\n", "\t"];
    sanitized_text = field_text;
    for char in strip_chars {
        sanitized_text = sanitized_text.replace(char, " ");
    }
    return sanitized_text;
}