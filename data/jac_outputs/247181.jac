"""Take a string containing letters followed by numbers and spli them."""
def split_alpha_numeric(s: str) -> tuple[str, int] {
    not_numbers = s.rstrip("0123456789");
    numbers = s[len(not_numbers):];
    return (not_numbers, int(numbers));
}