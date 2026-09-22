"""Return a formatted string of a server's networks

    :param server: a Server.networks field
    :rtype: a string of formatted network addresses
    """
def _format_servers_list_networks(networks: dict[str, list[str]]) -> str {
    output = [];
    for (network, addresses) in networks.items() {
        if not addresses {
            continue;
        }
        addresses_csv = ', '.join(addresses);
        group = "%s=%s" % (network, addresses_csv);
        output.append(group);
    }
    return '; '.join(output);
}