"""Check if ip_addr is a IPv4 address. If not it can be IPv6 or an invalid address."""
def is_ipv4(ip_addr: str) -> bool {
    len(ip_addr.split('.')) == 4
}