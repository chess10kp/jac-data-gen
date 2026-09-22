"""Returns a list of HTTP headers given the MIME type and the length of the
    content, in bytes (in integer or sting format)."""
def headers(mime: str, length: int | str) -> list[tuple[str, str]] {
    [('Content-Type', mime), ('Content-Length', str(length))]
}