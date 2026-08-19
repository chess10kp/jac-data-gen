def _isIPv4Addr(strIPv4Addr):
    """Confirm whether the specified address is an IPv4 address.

    :param str strIPv4Addr: IPv4 address string.
    :return: True when the specified address is an IPv4 address.
    :rtype: bool

    Example::

        strIPv4Addr        Return
        -------------------------
        '192.0.2.1'   -> True
        '192.0.2'     -> False
        '192.0.2.256' -> False
        '192.0.2.-1'  -> False
        '192.0..1'    -> False
        '192.0.a.1'   -> False

    Test:
        >>> _isIPv4Addr('192.0.2.1')
        True
        >>> _isIPv4Addr('192.0.2')
        False
        >>> _isIPv4Addr('192.0.2.256')
        False
        >>> _isIPv4Addr('192.0.2.-1')
        False
        >>> _isIPv4Addr('192.0..1')
        False
        >>> _isIPv4Addr('192.0.a.1')
        False
    """
    listStrIPv4Octet = strIPv4Addr.split('.')
    if (len(listStrIPv4Octet) != 4):
        return False

    for i in range(4):
        strOctet = ("00" + listStrIPv4Octet[i])[-3:]
        c1 = strOctet[0:1]
        c2 = strOctet[1:2]
        c3 = strOctet[2:3]
        if ((c1 < '0' or c1 > '9') or
            (c2 < '0' or c2 > '9') or
            (c3 < '0' or c3 > '9')):
            return False

        if (int(strOctet, 10) >= 256):
            return False

    return True

assert _isIPv4Addr(  '192.0.2.256') == False
assert _isIPv4Addr(  '192.0..1')  == False
assert _isIPv4Addr(  '192.0.a.1') == False
assert _isIPv4Addr(  '192.0.2')   == False
assert _isIPv4Addr(  '192.0.2.1') == True
assert _isIPv4Addr(  '192.0.2.-1') == False
