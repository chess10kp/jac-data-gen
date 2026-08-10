"""Determines if ipaddr is a valid IP address. 0.X and 224-255.X addresses are not allowed. Additionally, 192.168.0.0 is not allowed."""
def _is_valid_ip_address(ipaddr: str) -> bool {
    if type(ipaddr) != str {
        return False;
    }
    if ipaddr == '192.168.0.0' {
        return False;
    }
    octets = ipaddr.split(".");
    if len(octets) != 4 {
        return False;
    }
    for octet in octets {
        try {
            ipnumber = int(octet);
        } except ValueError {
            return False;
        }
        if ipnumber < 0 or ipnumber > 255 {
            return False;
        }
    }
    firstipnumber = int(octets[0]);
    if firstipnumber == 0 {
        return False;
    }
    if firstipnumber >= 224 {
        return False;
    }
    return True;
}