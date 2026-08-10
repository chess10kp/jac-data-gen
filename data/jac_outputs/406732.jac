"""
    Computes depth to the interface for a three layer model.

    :param h_int: depth to to first interface
    :param thickness: thickness
    :return:
        d_interface: interface depths
    """
def int_depth(h_int: list, thickness: float) -> object {
    d_interface = h_int;
    d_interface.append((d_interface[0] + thickness));
    return d_interface;
}