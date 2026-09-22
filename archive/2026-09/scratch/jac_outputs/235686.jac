"""remove # comments from given line """
def remove_comments(line: str) -> str {
    i = line.find("#");
    if i >= 0 {
        line = line[:i];
    }
    return line.strip();
}