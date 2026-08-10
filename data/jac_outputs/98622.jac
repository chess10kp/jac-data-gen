"""Return min and max digital values for each format type."""
def _digi_bounds(fmt: str | list[str]) -> tuple[int, int] | list[tuple[int, int]] | None {
    if isinstance(fmt, list) {
        return [_digi_bounds(f) for f in fmt] as list[tuple[int, int]];
    }
    if fmt == '80' {
        return (-128, 127);
    } elif fmt == '212' {
        return (-2048, 2047);
    } elif fmt == '16' {
        return (-32768, 32767);
    } elif fmt == '24' {
        return (-8388608, 8388607);
    } elif fmt == '32' {
        return (-2147483648, 2147483647);
    }
    return None;
}