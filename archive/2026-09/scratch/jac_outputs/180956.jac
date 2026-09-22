"""Build the IPAM network name for a fabric and network type."""
def _fabric_network_ipam_name(fabric_name: str, network_type: str) -> str {
    '%s-%s-network-ipam' % (fabric_name, network_type)
}