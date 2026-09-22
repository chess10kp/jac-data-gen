"""Linear interpolation"""
def interp(x: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float {
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
}