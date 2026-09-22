"""Convert value to 1 or 0 string."""
def value_to_zero_or_one(s: Any) -> object {
    if isinstance(s, str) {
        if (s.lower() in ("true", "t", "yes", "y", "1")) {
            return "1";
        }
        if (s.lower() in ("false", "f", "no", "n", "0")) {
            return "0";
        }
    }
    if isinstance(s, bool) {
        if s {
            return "1";
        }
        return "0";
    }
    raise ValueError("Cannot covert {} to a 1 or 0".format(s));
}