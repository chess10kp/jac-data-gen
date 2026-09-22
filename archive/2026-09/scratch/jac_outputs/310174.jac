"""Replace "space-newline" with "newline".

    Args:
        text (str): The string to work with

    Returns:
        The text with the appropriate fix.
    """
def space_newline_fix(text: str) -> str {
    space_newline = ' \n';
    fix = '\n';
    while space_newline in text {
        text = text.replace(space_newline, fix);
    }
    return text;
}