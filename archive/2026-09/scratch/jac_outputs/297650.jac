"""Escape text for inclusion in html"""
def _escape_html(text: str) -> str {
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace(" ", "&nbsp;");
}