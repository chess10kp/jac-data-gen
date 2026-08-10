"""Obtain number of decimal places to report on plots from axis spacing."""
def rounder(delta: float) -> int {
    if 0.001 <= delta < 0.01 {
        return 3;
    } elif 0.01 <= delta < 0.1 {
        return 2;
    } elif 0.1 <= delta < 1 {
        return 1;
    } elif 1 <= delta < 100000 {
        return 0;
    } else {
        return 0;
    }
}