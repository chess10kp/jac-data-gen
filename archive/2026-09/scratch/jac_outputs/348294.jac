"""
	Filter out items which are not instances of cls.
	"""
def sift(items: list[int | str | float | bool], cls: type) -> list[int | str | float | bool] {
    return [
        item
        for item in items
        if isinstance(item, cls)
    ] as list[int | str | float | bool];
}