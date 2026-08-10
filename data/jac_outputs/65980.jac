"""Return the padding needed to extend a message to a multiple of group_len
    in length.

    fillvalue can be a function or a literal value. If a function, it is called
    once for each padded character. Use this with fillvalue=random_english_letter
    to pad a message with random letters.
    """
def pad(message_len: int, group_len: int, fillvalue: str | callable[[], str]) -> str {
    padding_length = group_len - message_len % group_len;
    if padding_length == group_len {
        padding_length = 0;
    }
    padding = '';
    if callable(fillvalue) {
        for _ in range(padding_length) {
            padding += fillvalue();
        }
    } else {
        padding += fillvalue * padding_length;
    }
    return padding;
}