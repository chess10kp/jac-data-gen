"""Remove unbalanced punctuation (e.g parentheses or quotes) from text.

    Removes each opening punctuation character for which it can't find
    corresponding closing character, and vice versa.
    It can only handle one type of punctuation
    (e.g. it could strip quotes or parentheses but not both).
    It takes functions (is_open_char, is_close_char),
    instead of the characters themselves,
    so that we can determine from nearby characters whether a straight quote is
    an opening or closing quote.
    """
def _strip_unbalanced_punctuation(
    text: str,
    is_open_char: Callable[[str, int], bool],
    is_close_char: Callable[[str, int], bool]
) -> str {
    opening_chars: list[int] = [];
    unmatched_closing_chars: list[int] = [];
    for (idx, c) in enumerate(text) {
        if is_open_char(text, idx) {
            opening_chars.append(idx);
        } elif is_close_char(text, idx) {
            if opening_chars {
                opening_chars.pop();
            } else {
                unmatched_closing_chars.append(idx);
            }
        }
    }
    char_indices = [
        i
        for (i, _) in enumerate(text)
        if not (i in opening_chars or i in unmatched_closing_chars)
    ];
    return "".join([text[i] for i in char_indices]);
}