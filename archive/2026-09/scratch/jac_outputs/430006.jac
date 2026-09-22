"""
		Make a dictionary from two lists with elements of the first as the keys and second as values. If there are more elements in the first list, they are assigned None values and if there are more in the second list, they're dropped.
	"""
def mapLists(first: list[str], second: list[str]) -> dict[str, str | None] {
    index = 0;
    dict = {};
    while index < len(first) {
        f = first[index];
        s = second[index] if index < len(second) else None;
        dict[f] = s;
        index += 1;
    }
    return dict;
}