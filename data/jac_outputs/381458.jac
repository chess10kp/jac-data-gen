"""
    Checks if the current model entity is in fact a (data) reference
    class, for external elements reference.

    The data reference classes are used to refer external components of
    the model, for a loose connection.

    :rtype: bool
    :return: If the current class is a data reference to an entity model.
    """
def _class_is_reference(cls: Any) -> object {
    if (hasattr(cls, "data_reference") and (cls.data_reference == True)) {
        return True;
    }
    return False;
}