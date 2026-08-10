"""Convert magnitude to flux."""
def mag2flux(mag: float, zp: float = 25) -> float {
    10 ** ((2 / 5) * (zp - mag))
}