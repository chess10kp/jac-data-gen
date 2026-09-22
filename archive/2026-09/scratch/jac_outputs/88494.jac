"""Custom response payload handler after login or token refresh."""
def jwt_response_payload_handler(
    token: str, user: object | None = None, request: object | None = None
) -> dict[str, str] {
    return {'token': token};
}