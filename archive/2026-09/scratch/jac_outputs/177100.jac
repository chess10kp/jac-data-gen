"""Convert hex string to bytes."""
def hex_str_to_bytes(str_hex: str) -> bytes {
    str_hex = str_hex.lower();
    if str_hex.startswith("0x") {
        str_hex = str_hex[2:];
    }
    if len(str_hex) & 1 {
        str_hex = "0" + str_hex;
    }
    return bytes.fromhex(str_hex);
}