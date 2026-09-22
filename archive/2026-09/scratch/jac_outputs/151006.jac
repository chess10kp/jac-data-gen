"""
    returns whether the type or hint is a TypedDict
    """
def is_typed_dict(type_or_hint: type) -> bool {
    return issubclass(type_or_hint, dict) and hasattr(type_or_hint, "__annotations__");
}