"""
    Lookup a value in a Weld vector. This will add a cast the start and stop to 'I64'.

    Examples
    --------
    >>> slice_expr("v", 1, 2).code
    'slice(v, i64(1), i64(2))'

    """
def slice_expr(collection: Any, start: Any, count: Any) -> object {
    return "slice({collection}, i64({start}), i64({count}))".format(
        collection=collection, start=start, count=count
    );
}