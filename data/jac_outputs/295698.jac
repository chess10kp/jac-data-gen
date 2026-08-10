"""Given a unit and kernel, gives flat index into convolution (starts at 1)."""
def unit_mapping(unit: int, kern: str) -> int {
    if unit == 1 {
        mapping = {"shortcut": 0, "conv1": 1, "conv2": 2, "conv3": 3};
    } else {
        offset = 4 + 3 * (unit - 2);
        mapping = {"conv1": 0 + offset, "conv2": 1 + offset, "conv3": 2 + offset};
    }
    return mapping[kern] + 1;
}