"""
    Apply formatting to each item in an iterable. Returns a list.
    Each item is made available in the format_string as the 'item' keyword argument.
    example usage: ['png','svg','pdf']|format_list_items('{0}. {item}', [1,2,3]) -> ['1. png', '2. svg', '3. pdf']
    """
def format_list_items(
    items: Iterable[object],
    format_string: str,
    *args: object,
    **kwargs: object
) -> list[str] {
    return [format_string.format(*args, item=item, **kwargs) for item in items];
}