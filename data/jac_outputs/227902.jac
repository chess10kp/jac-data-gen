"""Returns a string to represent a value and time unit,
ensuring that it uses the right plural form of the unit."""
def _stringify_time_unit(value: int, unit: str) -> str {
    if value == 1 {
        return f"{value} {unit[:-1]}";
    } elif value == 0 {
        return f"less than a {unit[:-1]}";
    } else {
        return f"{value} {unit}";
    }
}