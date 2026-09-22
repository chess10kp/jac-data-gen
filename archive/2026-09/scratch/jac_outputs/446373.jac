"""Return an appropriate key for an attribute for sorting

    Attributes have a namespace that can be either ``None`` or a string. We
    can't compare the two because they're different types, so we convert
    ``None`` to an empty string first.

    """
def _attr_key(attr: Any) -> object {
    return ((attr[0][0] or ''), attr[0][1]);
}