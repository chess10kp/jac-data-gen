"""n-Significant Figures"""
def float_nsf(num: float | int | str, precision: int = 17) -> str {
    return ('{0:.%ie}' % (precision - 1)).format(float(num));
}