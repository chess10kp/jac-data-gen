"""
        :param list_of_elems: list of lists
        :param map_func: mapping dictionary
        :returns
            list with indexed elements
    """
def _elem2idx(list_of_elems: Any, map_func: Any) -> object {
    return [[map_func[x] for x in list_of] for list_of in list_of_elems];
}