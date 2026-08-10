"""
    Helper function to round a given value to a specific precision, for example *.5
    So 5.4 will be rounded to 5.5
    """
def round_to_decimal(value: Any, precision: float = 0.5) -> float {
    return round((precision * round((float(value) / precision))), 1);
}