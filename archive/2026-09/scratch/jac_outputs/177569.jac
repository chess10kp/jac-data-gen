"""Get the token from the property results."""
def _get_token(results: object) -> str | None {
    return getattr(results, 'token', None);
}