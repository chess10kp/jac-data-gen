"""Return True if addr is a valid IPv4 address, False otherwise."""
def is_ipv4_address(addr: str) -> bool {
    if not isinstance(addr, str) or not addr or addr.isspace() {
        return False;
    }
    octets = addr.split('.');
    if len(octets) != 4 {
        return False;
    }
    for octet in octets {
        if not octet.isdigit() {
            return False;
        }
        octet_value = int(octet);
        if octet_value < 0 or octet_value > 255 {
            return False;
        }
    }
    return True;
}