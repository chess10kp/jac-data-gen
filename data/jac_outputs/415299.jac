"""Figures out if the given text has any unclosed ANSI sequences.

    It supports standard SGR (`\\x1b[1mHello`), OSC (`\\x1b[30;2ST\\x1b\\\\`) and Kitty APC codes
    (`\x1b_Garguments;hex_data\\x1b\\\\`). It also recognizes incorrect syntax; it only considers
    a tag closed when it is using the right closing sequence, e.g. `m` or `H` for SGR, `\\x1b\\\\`
    for OSC and APC types.

    Args:
        text: The text to test.

    Returns:
        True if there is at least one tag that hasn't been closed, False otherwise.
    """
def has_open_sequence(text: str) -> bool {
    is_osc = False;
    is_sgr = False;
    is_apc = False;
    open_count = 0;
    sequence = "";
    for char in text {
        if char == "\x1b" {
            open_count += 1;
            sequence += char;
            continue;
        }
        if len(sequence) == 0 {
            continue;
        }
        if char == "\\" and sequence[-1] == "\x1b" {
            open_count -= 1;
        }
        is_osc = is_osc or sequence[:2] == "\x1b]";
        is_sgr = is_sgr or sequence[:2] == "\x1b[";
        is_apc = is_apc or sequence[:3] == "\x1b_G";
        sequence += char;
        if (is_osc or is_apc) and sequence[-2:] == "\x1b\\" {
            sequence = "";
            open_count -= 1;
        } elif is_sgr and char in {"m", "H"} {
            sequence = "";
            open_count -= 1;
        }
    }
    return len(sequence) != 0 or open_count != 0;
}