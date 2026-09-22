"""Checks if a value passed is a decimal percent (val>=0<=1.0)
        If it's between 1.0 and 100, it is converted to a decimal percent."""
def Pct_Converter(val: float, default_val: float = 0.7) -> float {
    if default_val > 1.0 and default_val <= 100.0 {
        default_val = default_val / 100.0;
    }
    if default_val > 100.0 {
        default_val = 0.7;
    }
    if val > 100 {
        return default_val;
    } elif val > 1.0 and val <= 100.0 {
        val = val / 100.0;
    }
    return val;
}