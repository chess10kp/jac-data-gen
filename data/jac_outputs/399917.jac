"""
    Parses out the X-Forwarded-For request header.

    This handles the bug that blows up when multiple IP addresses are
    specified in the header. The docs state that the header contains
    "The originating IP address", but in reality it contains a list
    of all the intermediate addresses. The first item is the original
    client, and then any intermediate proxy IPs. We want the original.

    Returns the first IP in the list, else None.

    """
def parse_xff(header_value: str) -> str | None {
    try {
        return header_value.split(',')[0].strip();
    } except (KeyError, AttributeError) {
        return None;
    }
}