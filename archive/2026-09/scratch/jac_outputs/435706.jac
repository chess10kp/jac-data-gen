"""Round to closest resolution."""
def round_to_fraction(val: float | int | None, res: float | int, decimals: int | None = None) -> float {
    if val is None {
        return 0.0;
    }
    if decimals is None and "." in str(res) {
        decimals = len(str(res).split('.')[1]);
    }
    scaled = float(round(val / res)) * float(res);
    if decimals is None {
        return float(round(scaled));
    }
    return float(round(scaled, decimals));
}