"""Split the coordinate arrays into nparts. Add extra_args to each part."""
def _split_arrays(arrays: list[list[int]], extra_args: list[str], nparts: int) -> list[list[list[int] | str]] {
    size = len(arrays[0]);
    n = size // nparts;
    strides = [(i * n, (i + 1) * n) for i in range(nparts - 1)];
    strides.append((strides[-1][-1], size));
    return [[x[low:high] for x in arrays] + extra_args for (low, high) in strides];
}