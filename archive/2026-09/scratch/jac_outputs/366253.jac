"""Used to generate 3x3 block slices.

arr[block33(0,1)] == arr[0:3, 3:6]
arr[block33(1,2)] == arr[3:6, 6:9]
"""
def block_3x3(i: int, j: int) -> tuple[slice, slice] {
    return (slice(i * 3, (i + 1) * 3), slice(j * 3, (j + 1) * 3));
}