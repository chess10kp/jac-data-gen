""" Return a list of all slots for a type, or object.

    Args:
        T: the type, or object to determine the slots for.

    Returns:
        The list of slot names, including those in base classes.
    """
def _all_slots(T: Any) -> object {
    if not isinstance(T, `type) {
        T = `type(T);
    }
    slots = [];
    def inner(T: Any, slots: Any) -> object {
        if hasattr(T, '__slots__') {
            slots += [s for s in T.__slots__];
        }
        for c in T.__bases__ {
            inner(c, slots);
        }
    }
    inner(T, slots);
    return slots;
}