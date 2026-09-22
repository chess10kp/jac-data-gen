"""
Return a slice covering all combinations with coordinate i along
axis.  (Effectively the hyperplane perpendicular to axis at i.)
"""
def all_but_axis(i: int, axis: int, num_axes: int) -> tuple[int | slice, ...] {
    the_slice = ();
    for j in range(num_axes) {
        if j == axis {
            the_slice = the_slice + (i,);
        } else {
            the_slice = the_slice + (slice(None),);
        }
    }
    return the_slice;
}