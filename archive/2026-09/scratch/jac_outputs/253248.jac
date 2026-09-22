"""Checks if given bytes object contains only uppercase elements."""
def bytes_isupper(x: bytes) -> bool {
    found_upper = False;
    for i in x {
        if ord('A') <= i <= ord('Z') {
            found_upper = True;
        } elif ord('a') <= i <= ord('z') {
            return False;
        }
    }
    return found_upper;
}