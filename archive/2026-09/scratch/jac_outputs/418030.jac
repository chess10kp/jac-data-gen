"""Merges two sorted sublists into a single sorted list."""
def merge(left: list[int], right: list[int]) -> list[int] {
    ret = [];
    li = ri = 0;
    while li < len(left) and ri < len(right) {
        if left[li] <= right[ri] {
            ret.append(left[li]);
            li += 1;
        } else {
            ret.append(right[ri]);
            ri += 1;
        }
    }
    if li == len(left) {
        ret.extend(right[ri:]);
    } else {
        ret.extend(left[li:]);
    }
    return ret;
}