""" returns the sign of x -> -1, 0, 1 """
def sign(x: Any) -> object {
    if (x < 0) {
        return -1;
    }
    if (x > 0) {
        return 1;
    }
    return 0;
}