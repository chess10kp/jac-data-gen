"""Determine if value is a float."""
def isfloat(value: str | int | float | bool) -> bool {
    try {
        float_val = float(value);
        return float_val == value or str(float_val) == value;
    } except ValueError {
        return False;
    }
}