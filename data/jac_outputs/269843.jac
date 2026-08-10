"""Try to get uuid from an object.

    Args:
        obj (Object): The object possibly containing uuid.

    Returns:
        Object: obj.uuid if it exists; otherwise, obj

    """
def uuid_from_obj(`obj: Any) -> object {
    if hasattr(`obj, "uuid") {
        return `obj.uuid;
    }
    return `obj;
}