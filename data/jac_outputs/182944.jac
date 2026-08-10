"""Flip the first and last characters if txt is a string."""
def flip_end_chars(txt: object) -> str {
    if isinstance(txt, str) and txt and len(txt) > 1 {
        (first, last) = (txt[0], txt[-1]);
        if first == last {
            return "Two's a pair.";
        }
        return "{}{}{}".format(last, txt[1:-1], first);
    }
    return "Incompatible.";
}