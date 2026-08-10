"""n-Significant Figures."""
def nsf(num: float, n: int = 1) -> float {
    while n - 1 < 0 {
        n += 1;
    }
    numstr = ("{0:.%ie}" % (n - 1)).format(num);
    return float(numstr);
}