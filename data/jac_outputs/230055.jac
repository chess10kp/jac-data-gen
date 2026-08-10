"""
Normally the result of list_items for listviews are a set of model objects.
But when you want a GROUP_BY query (with 'values' method), than
the result will be a dict. This method will help you find an item for
either objects or dictionaries.
"""
def get_attribute(`obj: dict[str, str] | object, value: str) -> str | int | float | bool | list[str] | dict[str, str] | None {
    if `type(`obj) == dict {
        return dict.get(`obj, value);
    }
    return getattr(`obj, value);
}