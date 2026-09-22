"""
    From the bookcontainer API. There's a typo until Sigil 0.9.5.
    """
def href_to_basename(href: Any, ow: Any = None) -> object {
    if (href is not None) {
        return href.split('/')[-1];
    }
    return ow;
}