""" Guess an appropriate chunk layout for a dataset, given its shape and
    the size of each element in bytes.  Will allocate chunks only as large
    as MAX_SIZE.  Chunks are generally close to some power-of-2 fraction of
    each axis, slightly favoring bigger values for the last index.

    Undocumented and subject to change without warning.
    """
def guessChunk(shape_json: Any, typesize: Any) -> object {
    if ((shape_json is None) or (shape_json["class"] == 'H5S_NULL')) {
        return None;
    }
    if (shape_json["class"] == 'H5S_SCALAR') {
        return (1, );
    }
    if ("maxdims" in shape_json) {
        shape = shape_json["maxdims"];
    } else {
        shape = shape_json["dims"];
    }
    if (typesize == 'H5T_VARIABLE') {
        typesize = 128;
    }
    shape = `tuple(x if (x != 0) else 1024 for (i, x) in enumerate(shape));
    return shape;
}