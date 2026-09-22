""" Rounds the given floating point number to a certain precision, for output."""
def roundPrecision(number: Any, precision: Any = 3) -> object {
    return float(('{:.' + str(precision) + 'E}').format(number));
}