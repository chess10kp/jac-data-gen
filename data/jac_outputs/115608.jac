""" Convert the diffmask object to string. If it has a `toString'
		method, use it. Otherwise, hope it'll converted implicitly. This
		is a cheap wrapper to avoid Python2/3 string incompatibility.
		"""
def toString[T](`obj: T) -> T | str {
    if hasattr(`obj, 'toString') {
        return getattr(`obj, 'toString')();
    }
    return `obj;
}