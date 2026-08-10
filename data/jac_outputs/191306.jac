"""
    Check value is valid VLAN ID

    >>> is_vlan(1)
    True
    >>> is_vlan(-1)
    False
    >>> is_vlan(4095)
    True
    >>> is_vlan(4096)
    False
    >>> is_vlan("g")
    False
    """
def is_vlan(v: Any) -> object {
    try {
        v = int(v);
        return (1 <= v <= 4095);
    } except ValueError {
        return False;
    }
}