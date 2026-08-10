"""Returns error response for missing parameters"""
def get_missing_param_response(data: str | None = None) -> dict[str, int | str | None] {
    return {"status": 400, "message": "Missing query parameter.", "data": data};
}