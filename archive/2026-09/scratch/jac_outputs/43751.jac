"""reverse reverses the items in a list of items

	Parameters:

	     items: list of items (can be a string)

	"""
def reverse(items: str | list[str]) -> list[str] {
    [items[i - 1] for i in range(len(items), 0, -1)]
}