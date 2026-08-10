"""For an HTML text, escapes characters that would be read as markup.

Adds in a line break after '>' to make reading the text easier
"""
def escape_html(text: str) -> str {
    str(text).replace("<", "&lt;").replace(">", "&gt;<br>")
}