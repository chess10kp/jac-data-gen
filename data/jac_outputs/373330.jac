"""Encode ``&``, ``<`` and ``>`` entities in ``text`` for HTML use."""
def html_encode(text: str) -> str {
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;');
}