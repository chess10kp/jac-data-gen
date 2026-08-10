"""Convert an ipv4 netmask into a network prefix length.

    If the input is already an integer or a string representation of
    an integer, then int(mask) will be returned.
       "255.255.255.0" => 24
       str(24)         => 24
       "24"            => 24
    """
def ipv4_mask_to_net_prefix(mask: int | str) -> int {
    if isinstance(mask, int) {
        return mask;
    }
    if not isinstance(mask, str) {
        raise TypeError(("mask '%s' is not a string or int" % mask));
    }
    try {
        return int(mask);
    } except ValueError {
        ;
    }
    if '.' not in mask {
        raise ValueError(("netmask '%s' does not contain a '.'" % mask));
    }
    toks = mask.split(".");
    if len(toks) != 4 {
        raise ValueError(("netmask '%s' had only %d parts" % (mask, len(toks))));
    }
    return sum([bin(int(x)).count('1') for x in toks]);
}