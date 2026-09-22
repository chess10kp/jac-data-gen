"""Convert a string to a boolean."""
def str_to_bool(boolstr: str, `default: bool = False) -> bool {
    boolstr = boolstr.lower();
    if boolstr in ('true', 'yes', 'on', '1') {
        return True;
    } elif boolstr in ('false', 'no', 'off', '0') {
        return False;
    }
    return `default;
}