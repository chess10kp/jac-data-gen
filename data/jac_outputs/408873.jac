glob MAX_COMPARE_LEN = 255 + 9;

"""Get the number of common leading elements beginning at data[i] and data[j]."""
def commonLeader(data: list[int], i: int, j: int) -> int {
    l = 0;
    try {
        while l < MAX_COMPARE_LEN and data[i + l] == data[j + l] {
            l += 1;
        }
    } except IndexError {
        ;
    }
    return l;
}