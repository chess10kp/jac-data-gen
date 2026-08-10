"""Email parsing function."""
def email_parser(email: str) -> list[str] {
    return [i.strip() for i in email.split(',')];
}