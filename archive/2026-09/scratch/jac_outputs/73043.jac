"""API Response common method."""
def api_response(
    success: bool,
    message: str,
    http_status_code: int | str,
    data: dict[str, object] = {}
) -> tuple[dict[str, object], int | str] {
    payload = {
        "success": success,
        "message": message,
        "data": data if isinstance(data, dict) else {}
    };
    return (payload, http_status_code);
}