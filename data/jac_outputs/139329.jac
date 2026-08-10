"""Convert <> to # if there are any HTML syntax tags.

Example: '<Hello>' will be converted to '#Hello' to avoid confusion
with HTML tags.
"""
def format_special_tokens(token: str) -> str {
    if token.startswith("<") and token.endswith(">") {
        return "#" + token.strip("<>");
    }
    return token;
}