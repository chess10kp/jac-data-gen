"""Get string defining the border mode."""
def padding_string(pad: tuple[int, int], pool_size: list[int]) -> str {
    if pad == (0, 0) {
        padding = 'valid';
    } elif pad == (pool_size[0] // 2, pool_size[1] // 2) {
        padding = 'same';
    } elif pad == (pool_size[0] - 1, pool_size[1] - 1) {
        padding = 'full';
    } else {
        raise NotImplementedError(
            "Padding {} could not be interpreted as any of the ".format(pad)
            + "supported border modes 'valid', 'same' or 'full'."
        );
    }
    return padding;
}