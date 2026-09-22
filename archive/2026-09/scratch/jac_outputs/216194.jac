"""Test if two values are equal to a given number of places."""
def almostequal(
    first: int | float, second: int | float, places: int = 7, printit: bool = True
) -> bool {
    if first == second {
        return True;
    }
    if round(abs(second - first), places) != 0 {
        if printit {
            print(round(abs(second - first), places));
            print(("notalmost: %s != %s to %i places" % (first, second, places)));
        }
        return False;
    }
    return True;
}