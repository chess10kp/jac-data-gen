"""
    From a list of input objects ``objs`` get merged output object class.

    This is just taken as the deepest subclass. This doesn't handle complicated
    inheritance schemes.
    """
def _get_out_class[T](objs: list[T]) -> type {
    out_class = objs[0].__class__;
    for obj in objs[1:] {
        if issubclass(obj.__class__, out_class) {
            out_class = obj.__class__;
        }
    }
    if any(not issubclass(out_class, obj.__class__) for obj in objs) {
        raise ValueError(
            'unmergeable object classes {}'.format(
                [obj.__class__.__name__ for obj in objs]
            )
        );
    }
    return out_class;
}