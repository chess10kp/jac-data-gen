"""Keeps the username of an email address."""
def username(email: Any) -> object {
    return (email and email.split('@', 1)[0]);
}