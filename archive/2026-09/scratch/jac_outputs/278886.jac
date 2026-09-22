"""
    returns the index evolution of each element
    of the list 1 compared to the index within list 2
    NB: if lists length do not match, place None value at missing index
    """
def list_evolution(list1: list, list2: list) -> list[int | None] {
    return [
        list2.index(x) - list1.index(x) if x in list2 else None
        for x in list1
    ];
}