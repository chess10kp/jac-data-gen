"""Convert altitude, in meters, to expected millibars."""
def hgt_to_mb(hgt: float, mslp: float = 1013.25) -> float {
    return mslp * (1 - hgt / 44307.69396) ** 5.2553026;
}