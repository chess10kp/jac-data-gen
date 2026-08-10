"""Default headers for GET or POST requests."""
def _defaultHeaders(token: str) -> dict[str, str] {
    return {
        'Accept': '*/*',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
    };
}