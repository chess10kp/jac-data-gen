"""Return the correct header name for an IP field with similar IPv4 and IPv6 usage.

    Keyword arguments:
    address_family -- desired address-family
    header_field -- header field name (use the IPv4 one)
    """
def af_to_ip_header_fields(address_family: Any, header_field: Any) -> object {
    headers = {"ipv6": {"tos": "tc", "id": "fl"}};
    return headers.get(address_family, {}).get(header_field, header_field);
}