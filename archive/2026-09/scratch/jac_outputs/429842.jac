"""Create an Error framework."""
def _Error(message: str, code: int = 400) -> dict[str, str | int] {
    return {"error": message, "code": code};
}