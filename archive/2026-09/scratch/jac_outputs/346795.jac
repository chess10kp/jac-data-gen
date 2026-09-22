"""Format a fraction to %.5f [numerator/denominator]."""
def fraction_str(numerator: int | float, denominator: int | float) -> str {
    if denominator > 0 {
        return "%.5f [%.5f/%d]" % (float(numerator) / denominator, numerator, denominator);
    }
    return "No Data";
}