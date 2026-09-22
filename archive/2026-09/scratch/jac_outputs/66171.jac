"""Helper to get optional details about named references.

Returns the dereferenced name as both value and repr if the name list is defined.
Otherwise returns the name index and its repr().
"""
def _get_name_info(name_index: int, name_list: list[str] | None) -> tuple[int | str, str] {
    if name_list is not None {
        return (name_list[name_index], name_list[name_index]);
    }
    return (name_index, repr(name_index));
}