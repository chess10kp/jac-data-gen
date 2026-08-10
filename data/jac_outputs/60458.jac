"""
Determines if the three input numbers are in sequence, either low-to-high
or high-to-low (with ties acceptable).
"""
def is_monotonic(a: float, b: float, c: float) -> bool {
    if b == a {
        return True;
    } elif b == c {
        return True;
    } elif (a > b) != (c > b) {
        return True;
    } else {
        return False;
    }
}