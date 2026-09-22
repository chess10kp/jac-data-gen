"""Returns a compact string describing the firewall rules."""
def _FirewallRulesToCell(firewall: Any) -> object {
    rules = [];
    for allowed in firewall.get('allowed', []) {
        protocol = allowed.get('IPProtocol');
        if not protocol {
            continue;
        }
        port_ranges = allowed.get('ports');
        if port_ranges {
            for port_range in port_ranges {
                rules.append('{0}:{1}'.format(protocol, port_range));
            }
        } else {
            rules.append(protocol);
        }
    }
    return ','.join(rules);
}