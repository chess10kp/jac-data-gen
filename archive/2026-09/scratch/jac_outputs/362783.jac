"""Backport of python 3.8's get_origin."""
def get_origin(type_annotation: type) -> type {
    origin = type_annotation?.__origin__;
    return (origin if origin is not None else type_annotation) as type;
}