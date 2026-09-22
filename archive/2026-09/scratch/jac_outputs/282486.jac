"""Error to catch page not found."""
def not_found(error: object) -> tuple[dict, int] {
    return ({"status": 404, "error": "Resource not found!"}, 404);
}