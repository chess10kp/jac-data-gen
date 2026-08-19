"""Confirm whether the specified address is an IPv4 address."""
def _isIPv4Addr(address: str) -> bool {
    parts = address.split('.');
    if len(parts) != 4 {
        return False;
    }
    for octet in parts {
        s = ("00" + octet)[-3:];
        c1 = s[0:1];
        c2 = s[1:2];
        c3 = s[2:3];
        if (c1 < '0' or c1 > '9') or (c2 < '0' or c2 > '9') or (c3 < '0' or c3 > '9') {
            return False;
        }
        if int(s, 10) >= 256 {
            return False;
        }
    }
    return True;
}
