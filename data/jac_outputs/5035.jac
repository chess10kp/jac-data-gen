"""
    Input arguments for function = tuple
    Coverts tuple into a list. I know, it is silly.
    Input example:
        get_vendors(("Neste", "Circle K"))
    Output example:
        ['Neste', 'Circle K']
    """
def get_vendors(ven: Any) -> object {
    vendors_list = list(ven);
    return vendors_list;
}