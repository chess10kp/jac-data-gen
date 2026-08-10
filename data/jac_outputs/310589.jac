"""Return stripped string unless string is empty string, then return None."""
def nonify_string(string: int | str | float | bool | None) -> str | None {
    if string is None {
        return None;
    }
    string = str(string).strip();
    if len(string) == 0 {
        return None;
    }
    return string;
}