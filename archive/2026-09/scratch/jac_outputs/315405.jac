"""Split a string of items into a list of converted items."""
def splitter(items: str, separator: str, convert_type: type) -> list[int] {
    [convert_type(x) for x in items.split(separator)]
}