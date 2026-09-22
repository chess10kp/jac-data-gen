"""Determine a field index.

    If the index passed is already a valid index, that index is returned.
    Otherwise, the header is searched for a field name matching any of
    the passed field names, and the index of the first one found is
    returned.

    If no matching field can be found, a ValueError is raised.
    """
def _field_index(header: list[str], field_names: list[str], index: int) -> int {
    if index > -1 {
        return index;
    }
    for (idx, value) in enumerate(header) {
        if value in field_names {
            print(f"Detected field '{value}' at index {idx}");
            return idx;
        }
    }
    expected_names = ', '.join(field_names);
    raise ValueError(f'No header field is named any of {expected_names}');
}