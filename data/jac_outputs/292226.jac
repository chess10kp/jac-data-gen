""" ['a','b,c','d'] ==> ['a','b','c','d']
    """
def _unflatten_dims(dims: Any) -> object {
    flatdims = [];
    for d in dims {
        flatdims.extend(d.split(','));
    }
    return flatdims;
}