"""Convert an array of lines into an object indexed by the line number.

Indexing from 0.
"""
def convert_lines_to_object(lines: list[str]) -> dict[str, str | int] {
    pad_to = len(str(len(lines)));
    `obj = {"count": len(lines)};
    for (i, line) in enumerate(lines) {
        `obj.update({("line" + str(i).rjust(pad_to, "0")): line});
    }
    return `obj;
}