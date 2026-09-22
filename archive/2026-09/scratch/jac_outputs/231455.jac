"""Check if string has .png extension."""
def check_str_png(s: object) -> str {
    if not isinstance(s, str) {
        raise TypeError("Input must be of type str");
    }
    if not s.endswith('.png') {
        raise ValueError("String must end with .png");
    }
    return s;
}