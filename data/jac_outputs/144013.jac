"""encode_packet

Take an already encoded data string and encode it to a BitShuffle data
packet.
"""
def encode_packet(
    data: bytes,
    checksum: int | str,
    seqnum: int | str,
    seqmax: int | str,
    compression: str
) -> str {
    msg = (
        "This is encoded with BitShuffle, which you can download "
        + "from https://github.com/charlesdaniels/bitshuffle"
    );
    compatlevel = "1";
    encoding = "base64";
    decoded = data.decode(encoding="ascii");
    fmt = "((<<{}|{}|{}|{}|{}|{}|{}|{}>>))";
    return fmt.format(
        msg, compatlevel, encoding, compression, seqnum, seqmax, checksum, decoded
    );
}