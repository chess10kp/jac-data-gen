"""
    Convert a string hex byte values into a byte string. The Hex Byte values may
    or may not be space separated.
    """
def HexToByte(hexStr: str) -> str {
    byte_chars = [];
    hexStr = ''.join(hexStr.split(" "));
    for i in range(0, len(hexStr), 2) {
        byte_chars.append(chr(int(hexStr[i:(i + 2)], 16)));
    }
    return ''.join(byte_chars);
}