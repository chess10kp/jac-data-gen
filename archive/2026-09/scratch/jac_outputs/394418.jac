"""Return a subdirectory used when a big case is split into several pieces."""
def splitdir(idx: list[int]) -> str {
    name = '';
    if len(idx) == 0 {
        return '';
    }
    for (ii, n) in enumerate(idx) {
        name += 'sp%d-split-%d/' % (ii, n);
    }
    return name[0:-1];
}