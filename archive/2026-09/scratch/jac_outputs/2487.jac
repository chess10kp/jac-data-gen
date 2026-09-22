"""Return axis label as "<value> (<unit>)"."""
def axLabel(value: int, unit: str) -> str {
    return str(value) + " (" + str(unit) + ")";
}