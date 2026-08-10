"""
    Indents all the lines of s by indent number of spaces
    """
def indent_string_block(s: str, indent: int = 2) -> str {
    indent_str = ' ' * indent;
    return indent_str + s.replace('\n', '\n' + indent_str);
}