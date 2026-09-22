"""Pretty-print a number of bytes."""
def _FormatBytes(byts: float) -> str {
    if byts > 2 ** 20.0 {
        byts /= 2 ** 20.0;
        return '%.2fm' % byts;
    }
    if byts > 2 ** 10.0 {
        byts /= 2 ** 10.0;
        return '%.2fk' % byts;
    }
    return str(byts);
}