"""
    Determines if the email is valid.

    Args:
        email: Email to test.

    Returns:
        bool: If the email is valid.
    """
def _is_valid_email(email: Any) -> object {
    if ("@" not in email) {
        return False;
    }
    if ("." not in email) {
        return False;
    }
    return True;
}