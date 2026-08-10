"""Payload Too Large"""
def error_413(error: BaseException) -> tuple[str, int] {
    return ("Uploaded file is too large", 413);
}