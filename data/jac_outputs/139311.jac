"""format a byte in a 2 character hex string"""
def hex2(byt: int) -> str {
    str = hex(byt)[2:];
    if len(str) == 1 {
        str = '0' + str;
    }
    return str.upper();
}