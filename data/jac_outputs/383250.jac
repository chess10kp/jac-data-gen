"""Convert a MAC address to XX:XX:XX:XX:XX:XX format."""
def mac_addr_convert(mac_address: str = "") -> str {
    try {
        mac = mac_address.replace(".", "");
        parts = [mac[i:i + 2].upper() for i in range(0, len(mac), 2)];
        return ":".join(parts);
    } except Exception {
        return mac_address;
    }
}