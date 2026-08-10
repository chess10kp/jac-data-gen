"""returns the intersection between two lists"""
def intersection(lst1: list[int], lst2: list[int]) -> list[int] {
    if lst1 == None or lst2 == None {
        return [];
    }
    return [value for value in lst1 if value in lst2];
}