"""
    Index the given object iteratively with values from the given iterable.
    :param obj: the object to index.
    :param iterable: The iterable to get keys from.
    :return: The value resulting after all the indexing.
    """
def index_by_iterable(`obj: Any, iterable: Any) -> object {
    item = `obj;
    for i in iterable {
        item = item[i];
    }
    return item;
}