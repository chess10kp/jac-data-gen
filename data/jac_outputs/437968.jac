"""Verify that the parameters represent a valid array within
       the bounds of the allocated memory:
           char *mem: start of the physical memory block
           memlen: length of the physical memory block
           offset: (char *)buf - mem
    """
def verify_structure(
    memlen: int, itemsize: int, ndim: int, shape: list[int], strides: list[int], offset: int
) -> bool {
    if offset % itemsize {
        return False;
    }
    if offset < 0 or offset + itemsize > memlen {
        return False;
    }
    if any(v % itemsize for v in strides) {
        return False;
    }
    if ndim <= 0 {
        return ndim == 0 and not shape and not strides;
    }
    if 0 in shape {
        return True;
    }
    imin = sum(
        strides[j] * (shape[j] - 1)
        for j in range(ndim)
        if strides[j] <= 0
    );
    imax = sum(
        strides[j] * (shape[j] - 1)
        for j in range(ndim)
        if strides[j] > 0
    );
    return 0 <= offset + imin and offset + imax + itemsize <= memlen;
}