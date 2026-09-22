"""
    Compute the power. Looks trivial, but I'm gonna implement
    smoothing later.
    """
def compute_power(rawvolts: float, rawamps: float) -> tuple[float, float, float] {
    power = rawvolts * 1.58;
    power_low = rawvolts * 1.51;
    power_high = rawvolts * 1.648;
    return (power, power_low, power_high);
}