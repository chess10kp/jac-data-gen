glob SHIFT_8 = 1 << 8;
glob SHIFT_16 = 1 << 16;

"""Return the smallest possible integer size for the given array."""
def getsize(data: list[int]) -> int {
    maxdata = max(data);
    if maxdata < SHIFT_8 {
        return 1;
    }
    if maxdata < SHIFT_16 {
        return 2;
    }
    return 4;
}