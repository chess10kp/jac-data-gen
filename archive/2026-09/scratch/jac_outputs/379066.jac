"""Return precision of input number."""
def get_precision(input_number: float) -> int {
    try {
        number_str = str(input_number);
        (_, decimalpart) = number_str.split(".");
        return len(decimalpart);
    } except Exception {
        return 0;
    }
}