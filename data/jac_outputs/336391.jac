"""Thresholding function."""
def thresholding(x: Any) -> object {
    if (x > 0.0) {
        y = 1;
    } else {
        y = 0.0;
    }
    return y;
}