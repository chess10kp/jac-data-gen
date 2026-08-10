"""Transform an integer confidence value (0-100) into a 0-10 scale string."""
def value_to_zero_ten(confidence_value: int) -> str {
    match confidence_value {
        case v if 0 <= v <= 4:
            return '0';
        case v if 5 <= v <= 14:
            return '1';
        case v if 15 <= v <= 24:
            return '2';
        case v if 25 <= v <= 34:
            return '3';
        case v if 35 <= v <= 44:
            return '4';
        case v if 45 <= v <= 54:
            return '5';
        case v if 55 <= v <= 64:
            return '6';
        case v if 65 <= v <= 74:
            return '7';
        case v if 75 <= v <= 84:
            return '8';
        case v if 85 <= v <= 94:
            return '9';
        case v if 95 <= v <= 100:
            return '10';
        case _:
            raise ValueError("Range of values out of bounds: %s" % confidence_value);
    }
}