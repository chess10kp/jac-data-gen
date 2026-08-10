"""Return the ratio of the number of nodes to the number of original DAIs.

    @rtype: dict
    @return: dictionary with one key ('') and the target number as a value
    """
def nodes_per_dai(tree: Any, context: Any) -> object {
    return {'': (len(tree) / float(len(context['da'])))};
}