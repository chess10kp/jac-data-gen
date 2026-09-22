"""Converts a six-byte hex form MAC address to six-byte decimal form.

    For example:
        00:1A:2B:3C:4D:5E converts to 0.26.43.60.77.94

    Returns:
        str, six-byte decimal form used in SNMP OIDs.
    """
def _mac_to_oid(mac: Any) -> object {
    fields = mac.split(':');
    oid_fields = [str(int(v, 16)) for v in fields];
    oid = '.'.join(oid_fields);
    return oid;
}