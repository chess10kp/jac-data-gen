"""
Convert a list of bytes into hex string
"""
def get_hex(input_list: list[str]) -> str {
    o = "";
    for i in input_list {
        o += "%02X" % ord(i);
    }
    return o;
}