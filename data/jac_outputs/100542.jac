"""Merges two sorted lists."""
def merge(lst1: list[int], lst2: list[int]) -> list[int] {
    if lst1 == [] {
        return lst2;
    } elif lst2 == [] {
        return lst1;
    } elif lst1[0] <= lst2[0] {
        return lst1[:1] + merge(lst1[1:], lst2);
    } else {
        return lst2[:1] + merge(lst1, lst2[1:]);
    }
}