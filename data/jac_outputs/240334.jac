"""
    Finds the start of a comment in the line, if any, and returns the line
    up to the comment, the token that started the comment (#, //, or /*),
    and the line after the comment token
    """
def strip_line_comment(line: str) -> tuple[str, str | None, str | None] {
    comment_tokens = ['#', '//', '/*'];
    index = 0;
    while index < len(line) {
        for token in comment_tokens {
            if index > len(line) - len(token) {
                continue;
            }
            if line[index:(index + len(token))] == token
                and line[0:index].replace('\\"', '').count('"') % 2 == 0 {
                return (line[0:index], token, line[(index + len(token)):]);
            }
        }
        index += 1;
    }
    return (line, None, None);
}