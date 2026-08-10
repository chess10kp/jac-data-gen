"""Convert string to float or NaN for "NA" for missing data."""
def float_or_na(s: str) -> float {
    return float("NaN") if s == "NA" else float(s);
}