"""\
	Interpolate between values a and b at float position p (0-1)
	"""
def Interpolate(a: float, b: float, p: float) -> float {
    a + (b - a) * p
}