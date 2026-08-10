"""Pre-flight ``Bucket`` name validation.

    :type name: str or :data:`NoneType`
    :param name: Proposed bucket name.

    :rtype: str or :data:`NoneType`
    :returns: ``name`` if valid.
    """
def _validate_name(name: Any) -> object {
    if (name is None) {
        return;
    }
    if not all([name[0].isalnum(), name[-1].isalnum()]) {
        raise ValueError("Bucket names must start and end with a number or letter.");
    }
    return name;
}