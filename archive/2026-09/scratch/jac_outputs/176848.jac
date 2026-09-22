"""IPv4 address filter: length > 7 and not a bogon IP. Return True if OK."""
def ipv4_filter(value: str, index: int = 0, pattern: object | None = None) -> bool {
    ip = value;
    if len(ip) < 8 {
        return False;
    }
    ip_bytes = ip.split('.');
    byte1 = int(ip_bytes[0]);
    byte2 = int(ip_bytes[1]);
    if ip.startswith('0.') {
        return False;
    }
    if ip.startswith('10.') {
        return False;
    }
    if ip.startswith('100.') and byte2 & 192 == 64 {
        return False;
    }
    if ip.startswith('127.') {
        return False;
    }
    if ip.startswith('169.254.') {
        return False;
    }
    if ip.startswith('172.') and byte2 & 240 == 16 {
        return False;
    }
    if ip.startswith('192.0.0.') {
        return False;
    }
    if ip.startswith('192.0.2.') {
        return False;
    }
    if ip.startswith('192.168.') {
        return False;
    }
    if ip.startswith('198.') and byte2 & 254 == 18 {
        return False;
    }
    if ip.startswith('198.51.100.') {
        return False;
    }
    if ip.startswith('203.0.113.') {
        return False;
    }
    if byte1 & 240 == 224 {
        return False;
    }
    if byte1 & 240 == 240 {
        return False;
    }
    if ip.endswith('.0') or ip.endswith('.255') {
        return False;
    }
    return True;
}