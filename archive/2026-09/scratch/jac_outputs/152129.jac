"""Indent content by the given number of spaces."""
def _indent(content: str | list[str], indent: int) -> str | list[str] {
    if indent == 0 {
        return content;
    }
    spaces = " " * indent;
    if isinstance(content, list) {
        return ["".join([spaces, line]) for line in content];
    }
    return "".join([spaces, content]);
}