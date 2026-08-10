"""Infer the data type of the value passed.

    Args:
        value (unknown): Value.

    Raises:
        ValueError : When the type can't be inferred.
    """
def infer_dtype(value: Any) -> object {
    if isinstance(value, bool) {
        return value;
    }
    for dtype in [float, int, str] {
        try {
            return dtype(value);
        } except ValueError {
            ;
        }
    }
    raise ValueError('Unable to infer type.');
}