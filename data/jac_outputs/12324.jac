"""Returns if the line is a LABEL node."""
def is_label_definition(line: str) -> bool {
    return line.startswith("LABEL ");
}