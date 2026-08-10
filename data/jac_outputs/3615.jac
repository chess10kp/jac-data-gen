"""Converts from temperatures from decidegrees Celsius to Kelvins."""
def _decicelsius_to_kelvins(temperatures_decicelsius: list[float] | float) -> list[float] | float {
    return temperatures_decicelsius * 0.1 + 273.15;
}