"""Rearrange list_[i:j] so that items < list_[i] are at
    the beginning and items >= list_[i] are at the end,
    and return the new index for list_[i].
    """
def _partition_2(list_: list[int], i: int, j: int) -> int {
    v = list_[i];
    k = i + 1;
    j -= 1;
    while k <= j {
        if list_[k] < v {
            k += 1;
        } else {
            (list_[k], list_[j]) = (list_[j], list_[k]);
            j -= 1;
        }
    }
    (list_[i], list_[j]) = (list_[j], list_[i]);
    return j;
}