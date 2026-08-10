"""Format IPv6 host address."""
def format_IPv6(host_address: str | None) -> str | None {
    if host_address {
        if "]" not in host_address {
            host_address = "[{0}]".format(host_address);
        }
    }
    return host_address;
}