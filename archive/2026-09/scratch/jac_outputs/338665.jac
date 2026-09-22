"""Return a list containing all items in 'L1' that are not in 'L2'"""
def unique(L1: Any, L2: Any) -> object {
    L2 = dict([(k, None) for k in L2]);
    return [
        item
        for item in L1
        if (item not in L2)
    ];
}