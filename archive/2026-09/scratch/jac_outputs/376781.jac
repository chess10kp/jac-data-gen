"""Return IP address of radio node on internal network"""
def internalNodeIP(node_id: Any) -> object {
    return '10.10.10.{:d}'.format(node_id);
}