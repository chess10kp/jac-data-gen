"""Add two strings of ints and return string."""
def sum_str(a: Any, b: Any) -> object {
    if ((a == '') or (a == ' ')) {
        a = 0;
    }
    if ((b == '') or (b == ' ')) {
        b = 0;
    }
    return str((int(a) + int(b)));
}