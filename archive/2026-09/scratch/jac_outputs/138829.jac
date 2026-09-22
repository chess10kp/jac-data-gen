"""Return sensitivity

counts: dict of counts, containing at least TP and FN
"""
def sensitivity_formula(counts: dict[str, int | float]) -> float {
    tp = counts['TP'];
    fn = counts['FN'];
    if not tp and not fn {
        return 0.0;
    }
    return tp / (tp + fn);
}