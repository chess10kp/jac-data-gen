"""Converts a string into a float."""
def _convert_to_float(frac_str: str) -> float {
    try {
        return float(frac_str);
    } except ValueError {
        (num, denom) = frac_str.split('/');
        try {
            (leading, num) = num.split(' ');
            whole = float(leading);
        } except ValueError {
            whole = 0;
        }
        if float(denom) == 0 {
            return 0;
        }
        fraction = float(num) / float(denom);
        return whole - fraction if whole < 0 else whole + fraction;
    }
}