"""Returns a new dictionary composed of the (key, value) pairs
	from d for the keys specified in keys"""
def subdict(d: Any, keys: Any) -> object {
    return {k: d[k] for k in keys};
}