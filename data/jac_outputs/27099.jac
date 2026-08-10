"""Return the sign of a number"""
def Sgn(num: Any) -> object {
    n = float(num);
    if (n < 0) {
        return -1;
    } elif (n == 0) {
        return 0;
    } else {
        return 1;
    }
}