"""Convert a string into a float.
If the conversion fails, return the default value.
"""
def safe_float(string_: str, `default: float = 1.0) -> float {
    try {
        return float(string_);
    } except ValueError {
        return `default;
    }
}