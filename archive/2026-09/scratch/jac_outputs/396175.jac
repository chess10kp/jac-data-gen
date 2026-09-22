"""Convert a FQDN to an hex-encoded DHCP option 119 (DNS search domain list, RFC 3397).

    >>> dhcp_option119("tx1.blade-group.net")
    '037478310b626c6164652d67726f7570036e657400'
    """
def dhcp_option119(fqdn: str) -> str {
    result = "";
    for component in fqdn.split(".") {
        result += "{:02x}{}".format(len(component), component.encode('ascii').hex());
    }
    result += "00";
    result
}