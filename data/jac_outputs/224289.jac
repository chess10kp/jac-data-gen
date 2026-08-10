"""Add the same tab size for each line in a block of lines."""
def reindent(string: str) -> str {
    "\n".join(l.strip() for l in string.strip().split("\n"))
}