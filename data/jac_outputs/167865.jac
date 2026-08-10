"""Verify requested colorspace is valid."""
def _get_space(space: str) -> str {
    space = space.lower();
    if space in ('hpluv', 'hsluv') {
        space = space[:3];
    }
    if space not in ('rgb', 'hsv', 'hpl', 'hsl', 'hcl') {
        raise ValueError(f'Unknown colorspace {space!r}.');
    }
    return space;
}