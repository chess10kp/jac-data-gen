"""Indent each line in a string."""
def indent(text: str) -> str {
    lines = text.replace("\r", "").split("\n");
    new_lines = [
        "" if len(line.strip()) == 0 else "\t" + line
        for line in lines
    ];
    return "\n".join(new_lines);
}