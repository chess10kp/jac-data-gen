"""
	Totals the number of matching characters between two strings

	Parameters
	----------
	a: str
	b: str

	Returns
	-------
	int
	"""
def matching(a: Any, b: Any) -> object {
    comp = zip(a, b);
    diff = abs((len(a) - len(b)));
    m = sum(
        1
        for (x, y) in comp
        if (x == y)
    );
    return (m - diff);
}