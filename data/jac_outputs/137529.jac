"""Takes a character from given string,
    shifts it secret times and return the
    character from lst depending on case of
    the taken character."""
def find_char(char: Any, secret: Any, lst: Any) -> object {
    pos = lst.index(char);
    offset = (pos + secret) % 26;
    ch = lst[offset];
    return ch;
}