"""slope sum function"""
def ssf(x0: float, x1: float) -> int | float {
    if x1 > x0 {
        return x1 - x0;
    }
    return 0;
}