"""
	Argument order: source following list, accumulated source's following list
	"""
def distinct(lst1: list[object], lst2: list[object]) -> list[object] {
    unique = set(lst1);
    return [x for x in lst2 if x not in unique];
}