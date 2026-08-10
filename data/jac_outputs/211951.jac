"""parse mac and mask string. (xx:xx:..:xx/yy:yy:...:yy)"""
def parse_masked_mac(s: str) -> tuple[str, str] {
    items = s.split("/", 1);
    if len(items) == 1 {
        return (items[0], "ff:ff:ff:ff:ff:ff");
    } elif len(items) == 2 {
        return (items[0], items[1]);
    } else {
        raise SyntaxError(s);
    }
}