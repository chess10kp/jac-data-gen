"""Returns True if all elements are in [0, 1]."""
def vector_in_01(x: Any) -> object {
    for element in x {
        if ((element < 0.0) or (element > 1.0)) {
            return False;
        }
    }
    return True;
}