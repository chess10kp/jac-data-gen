glob MAX_SPLIT_SIZE = 1 << 31;

"""Convert human-readable bytes to machine-readable bytes."""
def _get_split_size(split_size: int | str) -> int {
    if isinstance(split_size, str) {
        suffix = split_size[-2:];
        if suffix == "MB" {
            exp = 20;
        } elif suffix == "GB" {
            exp = 30;
        } else {
            raise ValueError('split_size has to end with either' '"MB" or "GB"');
        }
        split_size = int(float(split_size[:-2]) * (2 ** exp));
    }
    if split_size > MAX_SPLIT_SIZE {
        raise ValueError('split_size cannot be larger than 2GB');
    }
    return split_size;
}