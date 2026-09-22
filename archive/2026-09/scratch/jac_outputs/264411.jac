"""
    Convert a given value from Rankine to Kelvin and round it to 2 decimal places.
    Wikipedia reference: https://en.wikipedia.org/wiki/Rankine_scale
    Wikipedia reference: https://en.wikipedia.org/wiki/Kelvin
    """
def rankine_to_kelvin(rankine: float | int | str, ndigits: int = 2) -> float {
    return round(float(rankine) * 5 / 9, ndigits);
}