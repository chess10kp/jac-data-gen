"""dms - degrees from degrees, minutes, seconds"""
def dms(d: float, m: float, s: float) -> float {
    d + m / 60.0 + s / 3600.0
}