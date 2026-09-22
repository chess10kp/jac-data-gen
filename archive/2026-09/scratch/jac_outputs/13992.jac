"""Return last index and length of the longest zero-free subarray."""
def longuest_sub_array(arr: list[int]) -> tuple[int, int] | None {
    sub_arrays: list[tuple[int, int]] = [];
    last_index = 0;
    length = 0;
    for (i, l) in enumerate(arr) {
        if l != 0 {
            length += 1;
            last_index = i;
        } else {
            if last_index == i - 1 {
                sub_arrays.append((last_index, length));
            }
            length = 0;
        }
    }
    if sub_arrays == [(0, 0)] {
        print('The image cannot be cropped vertically');
        return None;
    }
    return max(sub_arrays, key=lambda (p: tuple[int, int]) { p[1]; });
}