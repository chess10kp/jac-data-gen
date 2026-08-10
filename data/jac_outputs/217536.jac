"""Get generic base types of a type or empty tuple if not possible.
    """
def get_generic_bases(tp: object) -> tuple[object, ...] {
    org = getattr(tp, '__origin__', None);
    a = (org,) if org else ();
    return a + getattr(tp, "__orig_bases__", ());
}