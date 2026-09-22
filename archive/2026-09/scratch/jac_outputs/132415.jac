"""
    According to the following RFC message body and length SHOULD NOT
    be included in responses status 1XX, 204 and 304.
    https://tools.ietf.org/html/rfc2616#section-4.4
    https://tools.ietf.org/html/rfc2616#section-4.3
    """
def has_message_body(status: Any) -> object {
    return ((status not in (204, 304)) and not (100 <= status < 200));
}