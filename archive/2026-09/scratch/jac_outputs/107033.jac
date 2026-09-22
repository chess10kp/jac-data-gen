"""Calculate the percentage without risk of division by zero."""
def percentage(fraction: float, total: float) -> str {
    p = 0 if total == 0 else 100.0 * fraction / total;
    return "%.2f%%" % p;
}