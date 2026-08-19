def is_valid_ipv4(ip_address: Any) -> object {
    octets = ip_address.split('.');
    if (len(octets) != 4) {
        return False;
    }
    for octet in octets {
        if not octet.isdigit() {
            return False;
        }
        if not (0 <= int(octet) <= 255) {
            return False;
        }
        if (octet != str(int(octet))) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_valid_ipv4('hello'));
}
