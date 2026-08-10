"""Return merged, sorted array and number of split inversions."""
def _merge_and_count_split_inv(left: Any, right: Any) -> object {
    (max_left, max_right) = (len(left), len(right));
    if ((max_left == 0) or (max_right == 0)) {
        return ((left + right), 0);
    }
    merged = [];
    inv_count = 0;
    i = j=0;
    while ((i < max_left) and (j < max_right)) {
        if (left[i] <= right[j]) {
            merged.append(left[i]);
            i += 1;
        } else {
            merged.append(right[j]);
            j += 1;
            inv_count += max_left - i;
        }
    }
    while (i < max_left) {
        merged.append(left[i]);
        i += 1;
    }
    while (j < max_right) {
        merged.append(right[j]);
        j += 1;
    }
    return (merged, inv_count);
}