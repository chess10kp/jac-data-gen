"""Return True if address is a valid IPv4 address."""
def validipaddr(address: str) -> bool {
    try {
        octets = address.split(".");
        if len(octets) != 4 {
            return False;
        }
        for x in octets {
            if " " in x {
                return False;
            }
            if not 0 <= int(x) <= 255 {
                return False;
            }
        }
    } except ValueError {
        return False;
    }
    return True;
}