glob MAX_INTERFACE_NAME_LEN = 15;

"""
    A helper function for interface/bridge name calculation.
    Since the name of interface must be less than 15 bytes. This util is to adjust the template automatically
    according to the length of vmhost name and port index. The leading characters (inje, muxy, mbr) will be shorten if necessary
    e.g.
    port 21 on vms7-6 -> inje-vms7-6-21
    port 121 on vms21-1 -> inj-vms21-1-121
    port 121 on vms121-1 -> in-vms121-1-121
    """
def adaptive_name(template: str, host: str, index: int) -> str {
    host_index_str = '-%s-%d' % (host, int(index));
    leading_len = MAX_INTERFACE_NAME_LEN - len(host_index_str);
    leading_characters = template.split('-')[0][:leading_len];
    return leading_characters + host_index_str;
}