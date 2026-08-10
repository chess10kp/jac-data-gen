obj IndexRef {
    has index: str;
}

"""Print indexed objects according to the Fortran syntax."""
def print_fortran_indexed(base: str, indices: list[IndexRef]) -> str {
    return base + ('' if len(indices) == 0 else '({})'.format(', '.join(i.index for i in indices)));
}