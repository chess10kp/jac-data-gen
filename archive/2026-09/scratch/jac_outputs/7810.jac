"""See setCounters() / getCounters() methods in IJ source, ij/gui/PointRoi.java."""
def get_counter(data: list[int], base: int) -> tuple[int, int] {
    _ = data[base];
    b1 = data[base + 1];
    b2 = data[base + 2];
    b3 = data[base + 3];
    counter = b3;
    position = (b1 << 8) + b2;
    return (counter, position);
}