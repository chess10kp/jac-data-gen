"""utf-8 decode a C string into a python string"""
def from_c_string(addr: Any) -> object {
    if (addr is None) {
        return None;
    }
    if (`type(addr) == str) {
        return addr;
    }
    return addr.decode('utf-8');
}