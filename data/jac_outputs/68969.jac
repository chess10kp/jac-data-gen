"""Return whether an IPv4 address string is valid."""
def is_ip_v4_address_valid(ip_v4_address: str) -> bool {
    octets = [
        int(i)
        for i in ip_v4_address.split(".")
        if i.isdigit()
    ];
    return len(octets) == 4 and all(0 <= int(octet) <= 254 for octet in octets);
}