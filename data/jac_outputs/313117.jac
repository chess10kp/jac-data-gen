"""@returns Chi-squared from a nuisance parameter"""
def gauss(pair: tuple[float, float], x: float) -> float {
    return ((pair[0] - x) / pair[1]) ** 2;
}