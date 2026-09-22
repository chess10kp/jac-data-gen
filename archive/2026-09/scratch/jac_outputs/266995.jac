"""Construct header with content type declaration for the server API calls.

    Returned dict can be added to the 'request' object.
    """
def content_type(content_type: Any = "application/json") -> object {
    return {'Content-type': content_type};
}