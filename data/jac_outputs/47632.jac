"""
    Turn any object into a html viewable entity.
    """
def htmlize(value: Any) -> object {
    return str(value).replace('<', '&lt;').replace('>', '&gt;');
}