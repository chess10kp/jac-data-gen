"""Removes duplicates from a sorted list."""
def RemoveDuplicate(Sortedlist: list[int]) -> list[int] {
    _Newlist = [];
    if not Sortedlist {
        return _Newlist;
    }
    prev = None;
    for element in Sortedlist {
        if element != prev {
            _Newlist.append(element);
            prev = element;
        }
    }
    return _Newlist;
}