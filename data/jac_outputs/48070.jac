"""Return a placeholder for an empty option based on longest entry length."""
def construct_none_displayer(entries: list[int | str], placeholder: str = '-') -> str {
    str_entries = [str(e) for e in entries];
    max_len = 0;
    for entry in str_entries {
        if len(entry) > max_len {
            max_len = len(entry);
        }
    }
    if max_len > 4 {
        none_displayer = placeholder * (max_len + 1);
    } else {
        none_displayer = placeholder * 5;
    }
    return none_displayer;
}