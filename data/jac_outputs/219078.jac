"""Determind is the pair will play indefinitly"""
def is_infinite(x: int, y: int) -> bool {
    (x, y) = (x, y) if x < y else (y, x);
    while x != y {
        y -= x;
        x *= 2;
        if x > y {
            return True;
        }
    }
    return False;
}