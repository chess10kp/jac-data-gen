"""
    parse 64 or 32-bit address from string into int
    """
def parse_addr(addrstr: Any) -> object {
    if addrstr.startswith('??') {
        return 0;
    }
    return int(addrstr.replace('`', ''), 16);
}