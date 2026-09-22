"""Compute power from start and end energy and times.
Return: power values
"""
def hb_energy_times_to_power(es: float, ee: float, ts: float, te: float) -> float {
    return (ee - es) / ((te - ts) / 1000.0);
}