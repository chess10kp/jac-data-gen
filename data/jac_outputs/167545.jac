"""Joins a name. This is the inverse of split_name, but x == join_name(split_name(x)) does not necessarily hold.

    Joining a name may also be subject to different schemes, but the most basic implementation is just joining all parts
    with a space.
    """
def join_name(*parts: str) -> str {
    return " ".join(parts);
}