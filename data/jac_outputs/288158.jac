"""Checks if a part (of multi-part body) looks like a directive.

Directives have application/json content-type and key 'directive' in the top-level JSON payload object."""
def is_directive(headers: dict[bytes, bytes], data: dict[str, str | int | bool | list | dict]) -> bool {
    return b"application/json" in headers[b"Content-Type"] and "directive" in data;
}