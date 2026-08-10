"""Converts a float to a fixed-point number given the number of
	precisionBits.  Ie. int(round(value * (1<<precisionBits))).
	"""
def floatToFixed(value: Any, precisionBits: Any) -> object {
    return int(round((value * (1 << precisionBits))));
}