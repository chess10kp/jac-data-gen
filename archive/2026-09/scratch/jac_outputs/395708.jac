"""
		O(n) time
		O(n) space
	"""
def intersection_of_arrays(l1: list[int], l2: list[int]) -> list[int] {
    set1 = set();
    for elem in l1 {
        set1.add(elem);
    }
    set2 = set();
    for elem in l2 {
        set1.add(elem);
    }
    res = [];
    for elem in set1 {
        if elem in set2 {
            res.append(elem);
        }
    }
    return res;
}