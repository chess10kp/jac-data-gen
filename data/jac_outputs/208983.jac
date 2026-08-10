"""Return a Markdown header."""
def markdown_header(header: str, level: int = 1) -> str {
    return ("\n" if level > 1 else "" + ("#" * level) + f" {header}\n");
}