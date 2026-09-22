"""This is the method to concatenate strings that are to be used in HMAC
    signature generation.

    Email should NOT be url encoded.
    """
def __sign_str_concat(email: str, expiration_str: str) -> str {
    return ' '.join([email, expiration_str]);
}