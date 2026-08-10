"""Return visible number in one row."""
def visible_onerow(array: list[int]) -> int {
    out_temp = 1;
    len_t = len(array);
    for i in range(len_t - 1) {
        for j in range(i + 1, len_t) {
            if array[i] < array[j] {
                break;
            }
        } else {
            out_temp += 1;
        }
    }
    return out_temp;
}