"""
    Removes all lines with line comments or block comments from the file content, so that the ast parser does not get confused.
    """
def shorten_file_by_removing_comments(content: str) -> str {
    lines = content.splitlines(keepends=True);
    delete = False;
    for (line_num, line) in enumerate(lines) {
        if line.strip().startswith("#") {
            lines[line_num] = "";
        }
        if line.strip().startswith('"""') or line.strip().startswith("'''") {
            delete = not delete;
            lines[line_num] = "";
        }
        if delete {
            lines[line_num] = "";
        }
    }
    lines = [line for line in lines if line.strip() != ""];
    return "".join(lines);
}