"""asssumes lst1 and lst2 are lists
    returns a list of tuples of the elementsts of lst1 and lst2"""
def mergeLists(lst1: list[object], lst2: list[object]) -> list[tuple[object, object]] {
    return list(zip(lst1, lst2));
}