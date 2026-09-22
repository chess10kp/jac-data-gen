glob BYTE_MASK = 0xFF;
glob MOD_256 = 0x100;

"""Computes the checksum byte of a packet.

    Packet must not contain a checksum already

    Args:
        packet (list):
            List of bytes for a packet.
            packet must not contain a checksum
            as the last element

    Returns:
        The computed checksum byte.
    """
def _compute_checksum(packet: list[int]) -> int {
    return ~(sum(packet[2:]) % MOD_256) & BYTE_MASK;
}