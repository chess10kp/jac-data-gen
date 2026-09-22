"""Collect alignment histogram."""
def collect_alignment(adict: dict[int, int], off: int) -> int {
    algn = 1;
    for ii in range(0, 5) {
        mask = 1 << ii;
        if off & mask {
            break;
        }
        algn *= 2;
    }
    if algn in adict {
        adict[algn] += 1;
    } else {
        adict[algn] = 1;
    }
    return algn;
}