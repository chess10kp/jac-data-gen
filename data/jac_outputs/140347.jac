""" get list of macs in leases
    leases is a dict from parse_dhcpd_config
    return macs as list for each host in leases dict
    """
def get_macs(leases: dict[str, dict[str, str]]) -> list[str] {
    return [leases[host]['mac'] for host in leases];
}