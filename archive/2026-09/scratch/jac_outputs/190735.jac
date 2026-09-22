""" Returns an IP address from an iface dict, preferring node_addr """
def get_address(iface: Any) -> object {
    if (iface["iface_addr"] is None) {
        return iface["node_addr"];
    } else {
        return iface["iface_addr"];
    }
}