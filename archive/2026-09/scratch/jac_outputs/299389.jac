"""Formatting integer as two digit hex value."""
def _hex(x: Any) -> object {
    return '0x{:02X}'.format(x);
}