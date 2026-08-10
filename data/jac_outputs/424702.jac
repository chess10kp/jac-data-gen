"""
    Shifts the pairing bit (True = 1, False = 0) 7 bits to the left and adds
    the device type
    """
def set_pairing_bit_on_device_type(pairing_bit: bool, device_type: int) -> object {
    return ((pairing_bit << 7) + device_type);
}