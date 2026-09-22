""" Adds "0" as a suffix or prefix if it needs it. """
def add_zero(s: str, i: int) -> str {
    if "." in s and len(s.split(".")[1]) == 1 {
        return s + "0";
    }
    if i != 0 and len(s) == 4 {
        return "0" + s;
    }
    return s;
}