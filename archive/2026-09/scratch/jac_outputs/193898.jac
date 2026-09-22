"""
    Convert a (pipe, port) combination into a 9-bit (devport) number
    NOTE: For now this is a Tofino-specific method
    """
def to_devport(pipe: int, port: int) -> int {
    return pipe << 7 | port;
}