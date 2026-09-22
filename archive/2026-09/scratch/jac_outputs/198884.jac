"""3 values between 0 and 1, summing to 1.

Error is the distance between the given 3d point and the expected 3d point.
"""
def `test(azote: float, phosphore: float, potassium: float) -> float {
    expected = (0.3, 0.2, 0.5);
    return 1 - (
        (azote - expected[0]) ** 2
        + (phosphore - expected[1]) ** 2
        + (potassium - expected[2]) ** 2
    ) ** 0.5;
}