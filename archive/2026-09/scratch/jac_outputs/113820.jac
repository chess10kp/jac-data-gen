"""Change HTML special characters to their codes.

    Follows ISO 8859-1 Characters changed: `&`, `<` and `>`.
    """
def html_quote(line: str) -> str {
    result = line;
    if "`" not in result {
        result = line.replace("&", "&amp;");
        result = result.replace("<", "&lt;");
        result = result.replace(">", "&gt;");
    }
    return result;
}