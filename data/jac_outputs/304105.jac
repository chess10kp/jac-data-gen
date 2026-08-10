"""Return True if password has at least one upper letter."""
def has_upper_letters(password: Any) -> object {
    return `any(char.isupper() for char in password);
}