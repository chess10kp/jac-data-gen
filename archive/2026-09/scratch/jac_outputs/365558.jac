"""Returns authorization header."""
def create_headers(bearer_token: str) -> dict[str, str] {
    return {"Authorization": f"Bearer {bearer_token}"};
}