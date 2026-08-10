"""heads up."""
def headers(token: str) -> dict[str, str] {
    {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
}