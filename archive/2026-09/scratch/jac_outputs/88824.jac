"""Converts a MAC address from the cisco format xxxx.xxxx.xxxx to the standard format
    accepted by IPAM xx:xx:xx:xx:xx:xx
    """
def convert_mac_address_format(cisco_mac: str) -> str {
    a = cisco_mac.replace('.', '');
    return ':'.join([a[0:2], a[2:4], a[4:6], a[6:8], a[8:10], a[10:12]]);
}