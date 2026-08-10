"""
    It transforms a MAC address from human readable string("00:11:22:33:44:55") to a raw string
    format("\x00\x11\x22\x33\x44\x55").
    """
def transform_string_mac_address_to_mac_address(string_mac_address: str) -> str {
    result = '';
    for octet in string_mac_address.split(':') {
        result += chr(int(octet, 16));
    }
    return result;
}