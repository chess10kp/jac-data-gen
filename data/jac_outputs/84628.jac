"""Indent text."""
def textindent(t: str, indent: int = 0) -> str {
    return "\n".join((" " * indent) + p for p in t.split("\n"));
}