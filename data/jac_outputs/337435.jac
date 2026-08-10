"""Remove an element from a list."""
def del_elements(ele: int, lst: list[int]) -> list[int] {
    new_lst = lst.copy();
    new_lst.remove(ele);
    return new_lst;
}