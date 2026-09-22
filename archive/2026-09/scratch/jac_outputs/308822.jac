"""Format a spatial reference given as a tuple."""
def format_reference(in_tuple: tuple[str, dict[str, int]]) -> str {
    out = in_tuple[0].split(':');
    res = in_tuple[1].get('res', None) or in_tuple[1].get('resolution', None);
    if res {
        out.append('-'.join(('res', str(res))));
    }
    return '_'.join(out);
}