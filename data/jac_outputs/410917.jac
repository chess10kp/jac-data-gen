"""Return sorted list of digits in number."""
def number_to_digits(num: Any) -> object {
    return sorted(int(ch) for ch in str(num));
}