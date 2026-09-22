"""
    Returns an IP address in the range
    192.168.0.0 - 192.168.255.255
    without using X.0 or X.255
    """
def get_vxlan_ip(n: int) -> str {
    (quot, rem) = divmod(n, 254) as tuple[int, int];
    return "192.168.%s.%s" % (quot + 1, rem + 1);
}