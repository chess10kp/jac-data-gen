"""Return whether ifIndex port_data belongs to an Ethernet port."""
def _is_ethernet(port_data: dict[str, int | str]) -> bool {
    valid = False;
    if 'ifType' in port_data {
        name = (port_data['ifName'] as str).lower();
        if port_data['ifType'] == 6 {
            if not name.startswith('vl') {
                valid = True;
            }
        }
    }
    return valid;
}