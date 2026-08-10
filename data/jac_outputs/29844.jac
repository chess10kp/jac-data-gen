"""Checks if the value is float. Which means it contains two non empty integer parts separated by ."""
def _is_float(value: str) -> bool {
    if "." not in value {
        return False;
    }
    (a, b) = value.split(".", 1);
    return a.isdigit() and b.isdigit();
}