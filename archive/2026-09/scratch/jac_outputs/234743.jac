"""Removes double spaces."""
def remove_spaces(line: str) -> str {
    line = line.lstrip();
    result = "";
    for (i, ch) in enumerate(line) {
        if i + 1 == len(line) or (ch != " " or (line[i + 1] != " " and line[i + 1] != "\n")) {
            result += ch as str;
        }
    }
    return result;
}