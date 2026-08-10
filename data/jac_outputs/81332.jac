"""Check if all given elements are equal."""
def list_equal(*elements: int | str | float | bool) -> bool {
    l0 = elements[0];
    for element in elements[1:] {
        if element != l0 {
            return False;
        }
    }
    return True;
}