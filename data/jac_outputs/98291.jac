"""Return a copy of a_list with index1 and index2 swapped."""
def swap(a_list: list[object], index1: int, index2: int) -> list[object] {
    b_list = a_list.copy();
    b_list[index1] = a_list[index2];
    b_list[index2] = a_list[index1];
    return b_list;
}