"""Return offset from prototype position."""
def get_offset(num: int, columns: int, spacing: tuple[int, int]) -> tuple[int, int] {
    x_offset = num % columns * spacing[0];
    y_offset = num // columns * spacing[1];
    return (x_offset, y_offset);
}