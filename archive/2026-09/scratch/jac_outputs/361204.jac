"""Return name of cell used to store character data"""
def get_cellname(ch: str) -> str {
    prefix = "font_";
    code = ord(ch);
    if code < 0x100 {
        cellname = "{:02X}".format(code);
    } elif code < 0x10000 {
        cellname = "{:04X}".format(code);
    } elif code < 0x1000000 {
        cellname = "{:06X}".format(code);
    } else {
        cellname = "{:X}".format(code);
    }
    return prefix + cellname;
}