"""List unique elements in input list, in order of first occurrence."""
def ordered_unique_list(in_list: list[int]) -> list[int] {
    out_list = [];
    for i in in_list {
        if i not in out_list {
            out_list.append(i);
        }
    }
    return out_list;
}