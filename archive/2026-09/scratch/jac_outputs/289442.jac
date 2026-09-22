"""For purposes of vocabulary creation ignore non-ascii documents."""
def keep_comment(
    text: str, min_ascii_fraction: float = 0.75, min_length: int = 1
) -> bool {
    len_total = len(text);
    if len_total < min_length {
        return False;
    }
    len_ascii = sum(c.isalpha() for c in text);
    frac_ascii = float(len_ascii) / float(len_total);
    if frac_ascii < min_ascii_fraction {
        return False;
    }
    return True;
}