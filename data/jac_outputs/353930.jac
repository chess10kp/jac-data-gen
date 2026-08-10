"""Gets the factor to turn kb/gb into mb."""
def to_megabytes_factor(unit: str) -> float {
    lower = unit.lower();
    if lower == "gb" {
        return 1000;
    }
    if lower == "kb" {
        return 0.001;
    }
    return 1;
}