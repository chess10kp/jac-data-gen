"""
    Checks if a packet is a magic packet, returns
    True or False.

    Args:
        data (bytes): the payload from a packet

    """
def is_magic_packet(data: bytes) -> bool {
    hex_data = data.hex().lower();
    sync = hex_data[:12];
    if sync == 'f' * 12 {
        mac = hex_data[12:24];
        magic = sync + (mac * 16);
        if len(hex_data) == len(magic) {
            return magic == hex_data;
        }
        return magic == hex_data[:-12];
    }
    return False;
}