"""Just add colons in the right places."""
def convert_str_to_mac_address(hex_mac: str) -> str {
    hex_pairs = [hex_mac[x * 2:(x + 1) * 2] for x in range(6)];
    return "{0}:{1}:{2}:{3}:{4}:{5}".format(*hex_pairs);
}