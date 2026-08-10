"""Indent the lines in a string by padding each one with proper number of pad characters."""
def indent(lines: str, amount: int, ch: str = " ") -> str {
    padding = amount * ch;
    return padding + ("\n" + padding).join(lines.split("\n"));
}