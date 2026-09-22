"""
        Checks whether the string is a whole word or not.

        @param {string} text Text containing a string.
        @param {number} start Start position of a string.
        @param {number} end End position of the string.

        @result {boolean} True if a string is a whole word.
                False if it's not.
    """
def isWhole(text: str, start: int, end: int) -> bool {
    alpha = 'abcdefghijklmnopqrstuvwxyz';
    if end - start == len(text) {
        return True;
    }
    if start {
        start -= 1;
    }
    if (
        text[start].lower() in alpha or text[end].lower() in alpha
        or text[start] == '#' and (text[end] == '(' or end == len(text))
        or text[start] == '.' or text[end] == '.'
    ) {
        return False;
    }
    return True;
}