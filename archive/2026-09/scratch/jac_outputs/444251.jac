"""Indent a multiline string by some number of spaces."""
def _indent(text: str, amount: int) -> str {
    indentation = amount * ' ';
    return indentation + ('\n' + indentation).join(text.split('\n'));
}