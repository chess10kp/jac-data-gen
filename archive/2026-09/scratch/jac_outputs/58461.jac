"""
    Given a result_collection (returned by a previous API call that
    returns a collection, like get_bundle_list() or search()), return a
    list of embedded items with each item in the returned list
    considered a result object.

    'result_collection' a JSON object returned by a previous API
    call. The parameter 'embed_items' must have been True when the
    result_collection was originally requested.May not be None.

    Returns a list, which may be empty if no embedded items were found.
    """
def get_embedded_items(result_collection: Any) -> object {
    assert (result_collection is not None);
    result = [];
    embedded_objects = result_collection.get('_embedded');
    if (embedded_objects is not None) {
        result = embedded_objects.get('items', result);
    }
    return result;
}