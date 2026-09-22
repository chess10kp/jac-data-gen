"""Presence condition mutator/wrapper: returns "W" when flag is True, else False."""
def warning(flag: bool = True) -> str | bool {
    return "W" if flag else False;
}