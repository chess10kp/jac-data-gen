"""Prevent parsing errors by converting <, >, & to their HTML codes."""
def sanitize_html(text: str) -> str {
    return text.replace('<', '&lt;').replace('>', '&gt;').replace('&', '&amp;');
}