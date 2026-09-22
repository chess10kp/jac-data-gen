"""Evaluates if a given password is valid. Its length must be higher than 0."""
def _is_valid_password(password: str | None) -> bool {
    if password is None or len(password) == 0 {
        return False;
    }
    return True;
}