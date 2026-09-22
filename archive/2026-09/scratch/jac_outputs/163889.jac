"""Quote unicode strings for URLs for Rocket."""
def quote_unicode(s: str) -> str {
    chars = [];
    for char in s {
        o = ord(char);
        if o < 128 {
            chars.append(char);
        } else {
            chars.append(hex(o).replace("0x", "%").upper());
        }
    }
    return "".join(chars);
}