"""
    Function for iterating over dictionary items with the same set-like
    behaviour on Py2.7 as on Py3.

    Passes kwargs to method."""
def viewitems(`obj: dict[str, str], **kwargs: str) -> list[tuple[str, str]] {
    func = `obj?.viewitems;
    if not func {
        func = `obj.items;
    }
    return func(**kwargs) as list[tuple[str, str]];
}