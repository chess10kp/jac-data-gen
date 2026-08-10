"""Merges two sorted lists into a single sorted list.

Returns new list. lst1 and lst2 are destroyed in the process."""
def merge(lst1: list[int], lst2: list[int]) -> list[int] {
    result = [];
    while lst1 or lst2 {
        if not lst1 {
            return result + lst2;
        } elif not lst2 {
            return result + lst1;
        }
        if lst1[0] < lst2[0] {
            result.append(lst1.pop(0));
        } else {
            result.append(lst2.pop(0));
        }
    }
    return result;
}