"""Sorts the dictionary and returns sorted dictionary

	Args; dictionary, 0 or 1
	0 - sort by key
	1 - sort by value

	Return
	sorted dictionary

	"""
def sort_wc(w_c: Any, sort_key: Any) -> object {
    sorted_w_c = {};
    if (sort_key == 1) {
        sorted_list = sorted(w_c, key=w_c.get, reverse=True);
    } else {
        sorted_list = sorted(w_c, reverse=True);
    }
    for word in sorted_list {
        sorted_w_c[word] = w_c[word];
    }
    return sorted_w_c;
}