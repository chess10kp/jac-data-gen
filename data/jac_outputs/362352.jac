"""
	repeat a value several k times.
	"""
def repeat_val(num: int, val: Any) -> object {
    return [val for _ in range((num - 1))];
}