glob INT32_MAX = 0x7FFFFFFF;
glob UINT32_MOD = 0x100000000;

"""Converts a completion and error code from 32-bit VPP notation to an integer."""
def _to_int(x: int) -> int {
    if x > INT32_MAX {
        return int(x - UINT32_MOD);
    }
    return int(x);
}