"""Function to be called when the response is not 200."""
def _send_not_success_response(status_code: int) -> dict[str, int | None] {
    return {"status": status_code, "data": None};
}