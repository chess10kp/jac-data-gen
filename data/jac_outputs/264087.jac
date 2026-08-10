"""Checks if number is a square."""
def is_square(apositiveint: int) -> bool {
    x = apositiveint // 2;
    seen = set([x]);
    while x * x != apositiveint {
        x = (x + apositiveint // x) // 2;
        if x in seen {
            return False;
        }
        seen.add(x);
    }
    return True;
}