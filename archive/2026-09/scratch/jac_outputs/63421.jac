"""
    The local part of an email address is case-sensitive, the domain part
    isn't.  This function lowercases the host and should be used in all email
    handling.
    """
def normalise_email(email: str) -> str {
    clean_email = email.strip();
    if '@' in clean_email {
        (local, host) = clean_email.rsplit('@', 1);
        return local + '@' + host.lower();
    }
    return clean_email;
}