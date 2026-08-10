"""Return (numerator/denominator)*100% in string."""
def percent(numerator: int | float, denominator: int | float) -> str {
    return '{}%'.format(numerator * 100 / denominator);
}