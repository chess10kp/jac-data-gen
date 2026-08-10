"""
	Formats value as a floating point number with decimals digits in the mantissa
	and returns the resulting string.
	"""
def formatFloat(number: int | float, decimals: int = 0) -> str {
    if decimals <= 0 {
        return "%f" % number;
    }
    return ("%." + str(decimals) + "f") % number;
}