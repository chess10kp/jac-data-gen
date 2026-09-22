"""Determines if there are any prices above a threshold."""
def any_above(prices: Any, threshold: Any) -> object {
    for x in prices {
        if (x > threshold) {
            return True;
        }
    }
    return False;
}