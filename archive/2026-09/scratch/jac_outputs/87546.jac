glob INT32_MAX = 1 << 31;

"""Validate given D2XX device index."""
def _validate_dev_idx(dev_idx: int) -> bool {
    return 0 <= dev_idx < INT32_MAX;
}