"""Whether both position are equal in the given tuples."""
def _is_equal_position(first: tuple[object, ...], second: tuple[object, ...], position: int) -> bool {
    if len(first) > position {
        if len(second) > position {
            return first[position] == second[position];
        }
        return first[position] is None;
    }
    if len(second) > position {
        return second[position] is None;
    }
    return True;
}