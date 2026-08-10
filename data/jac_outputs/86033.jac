"""
return float(number_str) if number_str is a number and is in the range [a, b],
otherwise return None
"""
def validate_number(number_str: str, a: float, b: float) -> float | None {
    try {
        n = float(number_str);
        if a <= n <= b {
            return n;
        }
        return None;
    } except ValueError {
        return None;
    }
}